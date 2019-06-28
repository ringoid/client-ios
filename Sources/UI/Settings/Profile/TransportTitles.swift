//
//  TransportTitles.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

extension Transport
{
    func title() -> String
    {
        switch self {
        case .unknown: return "profile_field_not_selected"
        case .walk: return "profile_field_transport_walk"
        case .publicTransport: return "profile_field_transport_public"
        case .cycle: return "profile_field_transport_cycle"
        case .motocycle: return "profile_field_transport_motocycle"
        case .car: return "profile_field_transport_car"
        case .taxi: return "profile_field_transport_taxi"
        case .chauffeur: return "profile_field_transport_chauffeur"
        }
    }
}
