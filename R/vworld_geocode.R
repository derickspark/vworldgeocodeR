vworld_geocode <- function(address_vec, api_key,
                           type = c("PARCEL", "ROAD"),
                           col_name = "address",
                           crs = "EPSG:4326",
                           sleep_sec = 0.12,
                           progress = TRUE,
                           verbose = FALSE,
                           timeout_sec = 10,
                           progress_label = NULL) {

  stopifnot(length(api_key) == 1, nzchar(api_key))
  type <- toupper(match.arg(type))
  addrs <- as.character(address_vec)
  n <- length(addrs)

  # 라벨 설정 (res1, res2 구분용)
  if (is.null(progress_label) || !nzchar(progress_label)) {
    label <- ""
  } else {
    label <- paste0("[", progress_label, "] ")
  }

  # ---- 안전 추출기: 다양한 JSON 구조에서 point$x/y를 찾아줌 ----
  .extract_xy <- function(out) {
    st <- tryCatch(out$response$status, error = function(e) NULL)
    if (!identical(st, "OK")) return(c(lat = NA_real_, lon = NA_real_))

    res <- tryCatch(out$response$result, error = function(e) NULL)
    if (is.null(res)) return(c(lat = NA_real_, lon = NA_real_))

    candidates <- list(
      res,
      if (is.list(res) && !is.null(res[[1]])) res[[1]] else NULL
    )

    for (cand in candidates) {
      if (is.null(cand)) next
      point <- tryCatch(cand[["point"]], error = function(e) NULL)
      if (is.null(point)) next
      x <- suppressWarnings(as.numeric(point[["x"]]))  # lon
      y <- suppressWarnings(as.numeric(point[["y"]]))  # lat
      if (is.finite(x) && is.finite(y)) return(c(lat = y, lon = x))
    }
    c(lat = NA_real_, lon = NA_real_)
  }

  geocode_one <- function(a) {
    if (is.na(a) || !nzchar(trimws(a))) return(c(lat = NA_real_, lon = NA_real_))

    url <- modify_url(
      "https://api.vworld.kr/req/address",
      query = list(
        service = "address",
        request = "getCoord",
        version = "2.0",
        address = enc2utf8(trimws(a)),
        refine = "true",
        simple = "false",
        format = "json",
        type = type,
        crs = crs,
        key = api_key
      )
    )

    resp <- try(GET(url,
                    timeout(timeout_sec),
                    user_agent("vworldgeocodeR/mini")))
    if (inherits(resp, "try-error") || http_error(resp)) {
      return(c(lat = NA_real_, lon = NA_real_))
    }

    txt <- content(resp, "text", encoding = "UTF-8")
    out <- suppressWarnings(fromJSON(txt, simplifyVector = FALSE))

    if (verbose) {
      st <- tryCatch(out$response$status, error = function(e) NA_character_)
      msg <- sprintf("status=%s raw_snippet=%s",
                     st,
                     substr(gsub("[\r\n]", " ", txt), 1, 120))
      message(msg)
    }

    .extract_xy(out)
  }

  out <- vector("list", n)
  if (progress && !verbose) {
    cat(sprintf("%s[0/%d] 시작...\n", label, n))
    flush.console()
  }

  start_time <- Sys.time()

  for (i in seq_len(n)) {
    out[[i]] <- tryCatch(
      geocode_one(addrs[i]),
      error = function(e) {
        if (verbose) {
          message(sprintf("%sindex %d error: %s",
                          label, i, conditionMessage(e)))
        }
        c(lat = NA_real_, lon = NA_real_)
      }
    )

    # ---- 진행상황 + ETA 표시 ----
    if (progress) {
      elapsed_sec <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      done <- i
      rate <- if (done > 0) elapsed_sec / done else NA_real_
      remaining_sec <- if (is.finite(rate)) rate * (n - done) else NA_real_
      pct <- (done / n) * 100

      if (verbose) {
        message(sprintf(
          "%s%d/%d (%.1f%%) | 현재주소: %s | 경과: %.1fs | 예상잔여: %.1fs (%.1f분)",
          label, done, n, pct,
          enc2utf8(addrs[i]),
          elapsed_sec,
          ifelse(is.finite(remaining_sec), remaining_sec, NA),
          ifelse(is.finite(remaining_sec), remaining_sec / 60, NA)
        ))
      } else {
        cat(sprintf(
          "\r%s%d/%d (%.1f%%) | 경과: %.1fs | 예상잔여: %.1fs (%.1f분)",
          label, done, n, pct,
          elapsed_sec,
          ifelse(is.finite(remaining_sec), remaining_sec, 0),
          ifelse(is.finite(remaining_sec), remaining_sec / 60, 0)
        ))
        flush.console()
      }
    }

    if (sleep_sec > 0) Sys.sleep(sleep_sec)
  }

  if (progress && !verbose) cat("\n완료.\n")

  lat <- vapply(out, function(x) x["lat"], numeric(1))
  lon <- vapply(out, function(x) x["lon"], numeric(1))

  df <- data.frame(tmp = addrs, lat = lat, lon = lon, check.names = FALSE)
  names(df)[1] <- col_name
  df
}
