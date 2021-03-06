# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

context("Parquet file reading/writing")

pq_file <- system.file("v0.7.1.parquet", package="arrow")

test_that("reading a known Parquet file to tibble", {
  skip_if_not_available("snappy")
  df <- read_parquet(pq_file)
  expect_true(tibble::is_tibble(df))
  expect_identical(dim(df), c(10L, 11L))
  # TODO: assert more about the contents
})

test_that("simple int column roundtrip", {
  df <- tibble::tibble(x = 1:5)
  pq_tmp_file <- tempfile() # You can specify the .parquet here but that's probably not necessary
  on.exit(unlink(pq_tmp_file))

  write_parquet(df, pq_tmp_file)
  df_read <- read_parquet(pq_tmp_file)
  expect_identical(df, df_read)
})

test_that("read_parquet() supports col_select", {
  skip_if_not_available("snappy")
  df <- read_parquet(pq_file, col_select = c(x, y, z))
  expect_equal(names(df), c("x", "y", "z"))

  df <- read_parquet(pq_file, col_select = starts_with("c"))
  expect_equal(names(df), c("carat", "cut", "color", "clarity"))
})

test_that("read_parquet() with raw data", {
  skip_if_not_available("snappy")
  test_raw <- readBin(pq_file, what = "raw", n = 5000)
  df <- read_parquet(test_raw)
  expect_identical(dim(df), c(10L, 11L))
})

test_that("write_parquet() handles various compression= specs", {
  skip_if_not_available("snappy")
  tab <- Table$create(x1 = 1:5, x2 = 1:5, y = 1:5)

  expect_parquet_roundtrip(tab, compression = "snappy")
  expect_parquet_roundtrip(tab, compression = rep("snappy", 3L))
  expect_parquet_roundtrip(tab, compression = c(x1 = "snappy", x2 = "snappy"))
})

test_that("write_parquet() handles various compression_level= specs", {
  skip_if_not_available("gzip")
  tab <- Table$create(x1 = 1:5, x2 = 1:5, y = 1:5)

  expect_parquet_roundtrip(tab, compression = "gzip", compression_level = 4)
  expect_parquet_roundtrip(tab, compression = "gzip", compression_level = rep(4L, 3L))
  expect_parquet_roundtrip(tab, compression = "gzip", compression_level = c(x1 = 5L, x2 = 3L))
})

test_that("write_parquet() handles various use_dictionary= specs", {
  tab <- Table$create(x1 = 1:5, x2 = 1:5, y = 1:5)

  expect_parquet_roundtrip(tab, use_dictionary = TRUE)
  expect_parquet_roundtrip(tab, use_dictionary = c(TRUE, FALSE, TRUE))
  expect_parquet_roundtrip(tab, use_dictionary = c(x1 = TRUE, x2 = TRUE))
})

test_that("write_parquet() handles various write_statistics= specs", {
  tab <- Table$create(x1 = 1:5, x2 = 1:5, y = 1:5)

  expect_parquet_roundtrip(tab, write_statistics = TRUE)
  expect_parquet_roundtrip(tab, write_statistics = c(TRUE, FALSE, TRUE))
  expect_parquet_roundtrip(tab, write_statistics = c(x1 = TRUE, x2 = TRUE))
})

test_that("make_valid_version()", {
  expect_equal(make_valid_version("1.0"), ParquetVersionType$PARQUET_1_0)
  expect_equal(make_valid_version("2.0"), ParquetVersionType$PARQUET_2_0)

  expect_equal(make_valid_version(1), ParquetVersionType$PARQUET_1_0)
  expect_equal(make_valid_version(2), ParquetVersionType$PARQUET_2_0)

  expect_equal(make_valid_version(1.0), ParquetVersionType$PARQUET_1_0)
  expect_equal(make_valid_version(2.0), ParquetVersionType$PARQUET_2_0)
})
