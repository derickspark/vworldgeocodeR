# vworldGeocode

간단한 vworld 주소 지오코딩 래퍼입니다. 도로명/지번 주소 모두 처리하며 진행률과 ETA를 표시합니다.

## 설치
```r
# 개발 버전
# remotes::install_github("derickspark/vworldgeocodeR")
```

## 사용 예시 
```r
library(vworldGeocode)

api_key <- Sys.getenv("VWORLD_GEOCODING2")  # .Renviron 등에 저장

df <- data.frame(도로명 = c("서울특별시 중구 세종대로 110"))
res <- vworld_geocode(df$도로명, api_key = api_key, type = "ROAD",
                      col_name = "address", progress_label = "demo")
print(res)
```

## 환경변수 예시 
```r
VWORLD_GEOCODING2=...your-key...
```


## LICENSE

MIT License

Copyright (c) 2025 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
