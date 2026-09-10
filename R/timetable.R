timetable_url <- paste0(
  "https://skema.ku.dk/tt/tt.asp?SDB=ku2627&language=EN&folder=Reporting",
  "&style=textspreadsheet&type=student+set&idtype=id&id=246494",
  "&weeks=1-53&days=1-7&periods=1-68&width=0&height=0",
  "&template=SWSCUST+student+set+textspreadsheet"
)

parse_ku_date <- function(value) {
  parts <- strsplit(trimws(tolower(value)), "\\s+")[[1]]
  months <- c(setNames(1:12, tolower(month.abb)), maj = 5L, okt = 10L)
  if (length(parts) != 3L || is.na(months[parts[2]])) {
    stop("Unrecognized KU timetable date: ", value)
  }
  date <- as.Date(
    sprintf("%s-%02d-%02d", parts[3], months[parts[2]], as.integer(parts[1])),
    format = "%Y-%m-%d"
  )
  if (is.na(date)) {
    stop("Invalid KU timetable date: ", value)
  }
  date
}

parse_ku_weeks <- function(value) {
  parts <- trimws(strsplit(value, ",", fixed = TRUE)[[1]])
  if (!length(parts) || any(!grepl("^[0-9]{1,2}(-[0-9]{1,2})?$", parts))) {
    stop("Unrecognized KU timetable weeks: ", value)
  }
  weeks <- unlist(lapply(parts, function(part) {
    ends <- as.integer(strsplit(part, "-", fixed = TRUE)[[1]])
    if (any(ends < 1L | ends > 53L) || ends[1] > tail(ends, 1)) {
      stop("Invalid KU timetable weeks: ", value)
    }
    seq.int(ends[1], tail(ends, 1))
  }))
  unique(weeks)
}

parse_timetable <- function(document) {
  clean_text <- function(node) {
    trimws(gsub(
      "[[:space:]\\x{00a0}]+",
      " ",
      xml2::xml_text(node),
      perl = TRUE
    ))
  }
  range <- clean_text(xml2::xml_find_first(
    document,
    "//span[@class='header-5-0-13']"
  ))
  bounds <- strsplit(range, "-", fixed = TRUE)[[1]]
  if (length(bounds) != 2L || anyNA(bounds)) {
    stop("Missing KU timetable date range.")
  }
  first <- parse_ku_date(bounds[1])
  last <- parse_ku_date(bounds[2])
  if (last < first || last - first > 371) {
    stop("Invalid timetable date range.")
  }
  dates <- seq(first, last, by = "day")
  weekdays <- c(
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  )
  required <- c("Activity", "Type", "Start", "End", "Weeks", "Room")
  sessions <- list()

  for (table in xml2::xml_find_all(document, "//table[@class='spreadsheet']")) {
    rows <- xml2::xml_find_all(table, "./tr")
    if (!length(rows)) {
      next
    }
    columns <- clean_text(xml2::xml_find_all(rows[[1]], "./td"))
    if (!all(required %in% columns)) {
      stop("Unexpected KU timetable columns.")
    }
    day <- clean_text(xml2::xml_find_first(table, "preceding-sibling::p[1]"))
    day_number <- match(day, toupper(weekdays))
    if (is.na(day_number)) {
      stop("Unrecognized KU timetable weekday: ", day)
    }

    for (row in rows[-1]) {
      values <- clean_text(xml2::xml_find_all(row, "./td"))
      if (length(values) != length(columns)) {
        stop("Incomplete KU timetable row.")
      }
      names(values) <- columns
      if (values["Activity"] != "Computational Statistics") {
        next
      }
      weeks <- parse_ku_weeks(values["Weeks"])
      selected <- dates[
        as.integer(format(dates, "%u")) == day_number &
          as.integer(format(dates, "%V")) %in% weeks
      ]
      if (!length(selected)) {
        stop("KU timetable weeks fall outside its date range.")
      }
      times <- values[c("Start", "End")]
      if (any(!grepl("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", times))) {
        stop("Invalid KU timetable time.")
      }
      times <- sub("^([0-9]):", "0\\1:", times)
      if (times[1] >= times[2]) {
        stop("Invalid KU timetable time range.")
      }
      type <- sub("^.*/", "", values["Type"])
      if (!type %in% c("Lecture", "Theoretical Exercises", "Exam")) {
        stop("Unrecognized KU timetable activity type: ", type)
      }
      sessions[[length(sessions) + 1L]] <- data.frame(
        date = selected,
        day = weekdays[day_number],
        type = unname(type),
        start = unname(times[1]),
        end = unname(times[2]),
        room = unname(values["Room"])
      )
    }
  }
  if (!length(sessions)) {
    stop("No Computational Statistics timetable entries found.")
  }
  sessions <- unique(do.call(rbind, sessions))
  sessions <- sessions[
    order(
      sessions$date,
      sessions$start,
      sessions$end,
      sessions$type,
      sessions$room
    ),
  ]
  rownames(sessions) <- NULL
  sessions
}

fetch_timetable <- function(url) {
  response <- httr2::request(url) |>
    httr2::req_timeout(30) |>
    httr2::req_perform()
  # KU serves Latin-1; xml2's UTF-8 default garbles Danish room names.
  xml2::read_html(httr2::resp_body_raw(response), encoding = "ISO-8859-1")
}

read_timetable <- function(path = here::here("data", "timetable.csv")) {
  timetable <- read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  timetable$date <- as.Date(timetable$date)
  timetable
}

update_timetable <- function(
  path = here::here("data", "timetable.csv"),
  fetch = fetch_timetable
) {
  timetable <- parse_timetable(fetch(timetable_url))
  if (file.exists(path) && isTRUE(all.equal(timetable, read_timetable(path)))) {
    message("The KU timetable is unchanged.")
    return(invisible(FALSE))
  }
  temporary <- tempfile("timetable-", tmpdir = dirname(path))
  on.exit(unlink(temporary), add = TRUE)
  write.csv(timetable, temporary, row.names = FALSE, fileEncoding = "UTF-8")
  if (!file.rename(temporary, path)) {
    stop("Could not save the KU timetable.")
  }
  message("Updated the KU timetable.")
  invisible(TRUE)
}

format_session <- function(
  timetable,
  date,
  type = "Lecture",
  afternoon = FALSE
) {
  session <- timetable[
    timetable$date == as.Date(date) &
      timetable$type == type &
      (timetable$start >= "12:00") == afternoon,
  ]
  if (!nrow(session)) {
    return(
      "Not listed in the current KU timetable. Please check the official timetable."
    )
  }
  date_label <- paste(
    session$day,
    paste0(
      as.integer(format(session$date, "%d")),
      " ",
      month.abb[as.integer(format(session$date, "%m"))]
    )
  )
  room <- sub("^(aud|øv) - *", "", session$room)
  room[room == ""] <- "Room to be announced"
  paste(
    paste0(
      date_label,
      ", ",
      session$start,
      "–",
      session$end,
      " · ",
      htmltools::htmlEscape(room)
    ),
    collapse = "; "
  )
}
