# R/zzz.R

.onAttach <- function(libname, pkgname) {
  # 패키지 attach 시 데이터셋 자동 로드
  utils::data("cty.rda", package = "vworldgeocodeR", envir = parent.env(environment()))
  utils::data("admi.rda", package = "vworldgeocodeR", envir = parent.env(environment()))
  utils::data("mega.rda", package = "vworldgeocodeR", envir = parent.env(environment()))

  packageStartupMessage(
    "cty, admi, mega 데이터셋이 자동으로 로드되었습니다. (vworldgeocodeR)"
  )
}
