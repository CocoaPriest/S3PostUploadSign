//
//  Package.swift
//  S3PostUploadSign
//
//  Created by Fabian Fett on 08/02/2017.
//  Copyright © 2017 Fabian Fett. All rights reserved.
//

import PackageDescription

let package = Package(
  name: "S3PostUploadSign",
  dependencies: [
    .Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git",
             majorVersion: 0)
    ]
)
