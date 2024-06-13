//
//  configUpdate.swift
//  Q
//
//  Created by Arun Induchoodan on 23/11/21.
//

import Foundation

public struct configUpdate{
    public let status:ERROR
    public let status_msg:String
    public let url:String
    public let oldJson:JSON?
    public let config:config
}
