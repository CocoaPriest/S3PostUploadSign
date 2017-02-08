//
//  sign.swift
//  S3PostUploadSign
//
//  Created by Fabian Fett on 07/02/2017.
//  Copyright © 2017 Fabian Fett. All rights reserved.
//

import Foundation
import CryptoSwift

// Documentation and ideas from:
// http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-HTTPPOSTForms.html
// https://leonid.shevtsov.me/post/demystifying-s3-browser-upload/

struct Credentials {
  let accessKey: String
  let secretAccessKey: String
  let dateString: String // yyyyMMdd
  let region: String
  let service: String
  let requestType: String
  
  init(accessKey: String, secretAccessKey: String, region: String,
       date: Date = Date(), service: String = "s3",
       requestType: String = "aws4_request")
  {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyyMMdd"
    
    self.accessKey       = accessKey
    self.secretAccessKey = secretAccessKey
    self.dateString      = dateFormatter.string(from: date)
    self.region          = region
    self.service         = service
    self.requestType     = requestType
  }
  
  var xAmzCredential: String {
    return accessKey + "/" + dateString + "/" + region + "/" +
           service + "/" + requestType
  }
}

public func sign(
  bucket: String,
  region: String,
  accessKey: String,
  secretAccessKey: String,
  fileName: String) -> (String, [String: String])
{
  let endpoint = "https://" + bucket + ".s3.amazonaws.com"
  
  let cred = Credentials(accessKey: accessKey, secretAccessKey: secretAccessKey,
                         region: region)
  let conditions = createConditions(bucket: bucket, key: fileName,
                                    cred: cred)
  let policy = createPolicy(timeoutInterval: 10 * 60, conditions: conditions)
  let base64policy = try! JSONSerialization.data(
    withJSONObject: policy,
    options: .init(rawValue: 0)).base64EncodedString()
  
  // Each form field that you specify in a form (except x-amz-signature, file, 
  // policy, and field names that have an x-ignore- prefix) must appear in the
  // list of conditions.
  
  var params: [String: String] = [:]
  
  conditions.forEach { (dict) in
    dict.forEach { (key, value) in
      params[key] = value
    }
  }
  
  params["policy"] = base64policy
  params["x-amz-signature"] = createSignature(cred: cred,
                                              policyBase64: base64policy)
  
  return (endpoint, params)
}

private func createPolicy(timeoutInterval: TimeInterval,
                          conditions: [[String: String]])
  -> [String: Any]
{
  let expireDateFormatter = DateFormatter()
  expireDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
  expireDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
  
  return [
    "expiration": expireDateFormatter.string(
      from: Date(timeIntervalSinceNow: timeoutInterval)),
    "conditions": conditions
  ]
}

private func createConditions(bucket: String, key: String, cred: Credentials)
  -> [[String: String]]
{
  let nowDateFormatter = DateFormatter()
  nowDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
  nowDateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
  
  return [
    ["acl": "private"],
    ["bucket": bucket],
    ["key": key],
    ["success_action_status": "201"],
    ["x-amz-algorithm": "AWS4-HMAC-SHA256"],
    ["x-amz-credential": cred.xAmzCredential],
    ["x-amz-date": nowDateFormatter.string(from: Date())]
  ]
}

private func hmac(_ key: [UInt8], _ message: String) -> [UInt8] {
  let hmac = HMAC(key: key, variant: .sha256)
  return try! hmac.authenticate([UInt8](message.utf8))
}

private func createSignature(cred: Credentials,
                             policyBase64: String)
  -> String
{
  
  let secretKey     = [UInt8](("AWS4" + cred.secretAccessKey).utf8)
  let dateKey       = hmac(secretKey, cred.dateString)
  let dateRegionKey = hmac(dateKey, cred.region)
  let dateRegionServiceKey = hmac(dateRegionKey, cred.service)
  let signingKey    = hmac(dateRegionServiceKey, cred.requestType)
  let signed        = hmac(signingKey, policyBase64)
  
  return signed.map{String(format: "%02X", $0)}.joined().lowercased()
}
