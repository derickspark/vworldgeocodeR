# R/zzz.R

.onAttach <- function(libname, pkgname) {
  # 패키지 attach 시 전역환경(.GlobalEnv)으로 자동 로드
  for (nm in c("cty", "admi", "mega")) {
    try(
      utils::data(list = nm, package = pkgname, envir = .GlobalEnv),
      silent = TRUE
    )
  }
  packageStartupMessage("cty, admi, mega 데이터셋을 .GlobalEnv로 자동 로드했습니다. (vworldgeocodeR)")
}
