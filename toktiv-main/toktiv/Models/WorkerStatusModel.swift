//
//  WorkerStatusModel.swift
//  toktiv
//
//  Created by Developer on 27/11/2020.
//

import Foundation


// MARK: - TwilioAccessResponse
struct WorkerStatusModel: Codable {
    let accountSid: String?
    let activityName: String?
    let activitySid: String?
    let attributes: String?
    let available: Bool?
    let dateCreated: String?
    let dateStatusChanged: String?
    let dateUpdated: String?
    let friendlyName: String?
    let sid: String?
    let workspaceSid: String?
    let url: String?
    let links: Links?

    enum CodingKeys: String, CodingKey {
        case accountSid = "account_sid"
        case activityName = "activity_name"
        case activitySid = "activity_sid"
        case attributes = "attributes"
        case available = "available"
        case dateCreated = "date_created"
        case dateStatusChanged = "date_status_changed"
        case dateUpdated = "date_updated"
        case friendlyName = "friendly_name"
        case sid = "sid"
        case workspaceSid = "workspace_sid"
        case url = "url"
        case links = "links"
    }
}

// MARK: - Links
struct Links: Codable {
    let cumulativeStatistics: String?
    let reservations: String?
    let realTimeStatistics: String?
    let statistics: String?
    let workerChannels: String?
    let channels: String?
    let workerStatistics: String?
    let workspace: String?
    let activity: String?

    enum CodingKeys: String, CodingKey {
        case cumulativeStatistics = "cumulative_statistics"
        case reservations = "reservations"
        case realTimeStatistics = "real_time_statistics"
        case statistics = "statistics"
        case workerChannels = "worker_channels"
        case channels = "channels"
        case workerStatistics = "worker_statistics"
        case workspace = "workspace"
        case activity = "activity"
    }
}
