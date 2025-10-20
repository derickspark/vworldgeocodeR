#' 단일 주소를 VWorld API로 지오코딩
#'
#' @param address 주소(문자열)
#' @param api_key VWorld API 키
#' @param parcel 논리값, 지번 주소 사용 여부 (기본값 TRUE)
#' @param road 논리값, 도로명 주소 사용 여부 (기본값 FALSE)
#' @return 데이터프레임(address, lat, lon, status)
#' @export
vworld_geocode <- function(address, api_key, parcel = TRUE, road = FALSE) {
  url <- "https://api.vworld.kr/req/address"
  
  # 주소 유형 선택: road가 TRUE면 road 우선, 아니면 parcel
  addr_type <- ifelse(road, "road",
                      ifelse(parcel, "parcel", "road"))
  
  params <- list(
    service = "address",
    request = "getcoord",
    version = "2.0",
    address = address,
    refine = "true",
    simple = "false",
    format = "json",
    type = addr_type,
    key = api_key
  )
  
  full_url <- paste0(
    url, "?service=", params$service,
    "&request=", params$request,
    "&version=", params$version,
    "&address=", RCurl::curlEscape(params$address),
    "&refine=", params$refine,
    "&simple=", params$simple,
    "&format=", params$format,
    "&type=", params$type,
    "&key=", params$key
  )
  
  response <- httr::GET(full_url)
  
  if (httr::http_status(response)$category == "Success") {
    content <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
    if (content$response$status == "OK") {
      coords <- content$response$result$point
      return(data.frame(
        address = address,
        lat = as.numeric(coords$y),
        lon = as.numeric(coords$x),
        status = paste0("success (", addr_type, ")"),
        stringsAsFactors = FALSE
      ))
    } else {
      return(data.frame(
        address = address,
        lat = NA,
        lon = NA,
        status = paste("failed:", content$response$status),
        stringsAsFactors = FALSE
      ))
    }
  } else {
    return(data.frame(
      address = address,
      lat = NA,
      lon = NA,
      status = paste("failed: HTTP", httr::http_status(response)$reason),
      stringsAsFactors = FALSE
    ))
  }
}
