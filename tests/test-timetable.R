source(here::here("R", "timetable.R"), local = TRUE)

saved_timetable <- function() {
  xml2::read_html(
    here::here("tests", "fixtures", "ku-timetable.html"),
    encoding = "ISO-8859-1"
  )
}

test_that("KU week ranges expand to dated sessions with the correct rooms", {
  sessions <- parse_timetable(saved_timetable())

  expect_equal(nrow(sessions), 31L)
  expect_equal(range(sessions$date), as.Date(c("2026-09-01", "2026-11-06")))
  expect_equal(as.integer(table(sessions$type)), c(3L, 20L, 8L))
  expect_false(any(format(sessions$date, "%V") == "42"))

  first <- subset(sessions, date == as.Date("2026-09-01"))
  expect_equal(first$day, "Tuesday")
  expect_equal(first$start, "10:00")
  expect_match(first$room, "Bülowsvej 17", fixed = TRUE)
  expect_match(
    sessions$room[sessions$date == as.Date("2026-09-08")],
    "A2-70.02",
    fixed = TRUE
  )

  thursday <- subset(sessions, date == as.Date("2026-09-17"))
  expect_equal(thursday$start, c("08:00", "10:00", "13:00"))
  expect_match(thursday$room[1], "A2-70.03", fixed = TRUE)
})

test_that("calendar dates also work after the academic year crosses January", {
  document <- saved_timetable()
  weeks <- xml2::xml_find_all(
    document,
    "//table[@class='spreadsheet']/tr[td[1]='Computational Statistics']/td[7]"
  )
  xml2::xml_set_text(weeks, "1")

  sessions <- parse_timetable(document)
  expect_true(all(format(sessions$date, "%Y") == "2027"))
  expect_equal(
    unique(sessions$date[sessions$day == "Tuesday"]),
    as.Date("2027-01-05")
  )
})

test_that("unexpected or invalid source data is rejected", {
  expect_error(
    parse_timetable(xml2::read_html("<html>Unavailable</html>")),
    "date"
  )

  document <- saved_timetable()
  weeks <- xml2::xml_find_first(
    document,
    "//table[@class='spreadsheet']/tr[td[1]='Computational Statistics']/td[7]"
  )
  xml2::xml_set_text(weeks, "36, unknown")
  expect_error(parse_timetable(document), "week")

  document <- saved_timetable()
  xml2::xml_remove(xml2::xml_find_all(
    document,
    "//table[@class='spreadsheet']/tr/td[.='Room']"
  ))
  expect_error(parse_timetable(document), "columns")
})

test_that("only timetable changes replace the saved data", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path))
  fetch <- function(url) saved_timetable()
  expect_true(update_timetable(path, fetch))
  original <- readBin(path, "raw", n = file.info(path)$size)
  original_mtime <- file.info(path)$mtime

  document <- saved_timetable()
  xml2::xml_set_text(
    xml2::xml_find_first(document, "//span[@class='footer-4-0-13']"),
    "11 sep 2026"
  )
  expect_false(update_timetable(path, function(url) document))
  expect_identical(file.info(path)$mtime, original_mtime)
  expect_identical(readBin(path, "raw", n = length(original)), original)

  room <- xml2::xml_find_first(
    document,
    "//table[@class='spreadsheet']/tr[td[1]='Computational Statistics']/td[8]"
  )
  xml2::xml_set_text(room, "New room")
  expect_true(update_timetable(path, function(url) document))
  expect_equal(read_timetable(path)$room[1], "New room")
})

test_that("fetch and parse failures leave the saved data intact", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path))
  update_timetable(path, function(url) saved_timetable())
  original <- read_timetable(path)

  expect_error(
    update_timetable(path, function(url) stop("KU is unavailable")),
    "KU is unavailable"
  )
  expect_error(
    update_timetable(path, function(url) xml2::read_html("<html>Error</html>")),
    "date"
  )
  expect_identical(read_timetable(path), original)
})

test_that("inline details distinguish morning classes and afternoon presentations", {
  timetable <- parse_timetable(saved_timetable())
  expect_equal(
    format_session(timetable, "2026-09-01"),
    "Tuesday 1 Sep, 10:00–12:00 · A1-01.01 Festauditoriet, Bülowsvej 17, Frederiksberg"
  )
  expect_match(
    format_session(timetable, "2026-09-17", "Theoretical Exercises"),
    "08:00–10:00 · A2-70.03",
    fixed = TRUE
  )
  expect_match(
    format_session(timetable, "2026-09-17", afternoon = TRUE),
    "13:00–15:00",
    fixed = TRUE
  )
  expect_match(format_session(timetable, "2026-10-13"), "Not listed")

  timetable$room[1] <- "<script>alert(1)</script>"
  expect_match(
    format_session(timetable, "2026-09-01"),
    "&lt;script&gt;",
    fixed = TRUE
  )
})
