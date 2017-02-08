//
//  signTest.swift
//  S3PostUploadSign
//
//  Created by Fabian Fett on 07/02/2017.
//  Copyright © 2017 Fabian Fett. All rights reserved.
//

import XCTest
import S3PostUploadSign


class signTest: XCTestCase {
  
  func testSign() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    self.measure {
      let (endpoint, params) = sign(
        bucket: "test",
        region: "eu-central-1",
        accessKey: "",
        secretAccessKey: "",
        fileName: "test.csv.gz"
      )
      
      print(endpoint)
      print(params)
      
      XCTAssert(true)
    }
    
  }
    
}
