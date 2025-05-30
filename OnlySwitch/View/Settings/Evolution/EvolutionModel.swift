//
//  EvolutionModel.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2023/5/27.
//

import Dependencies
import Foundation
import Switches

struct EvolutionItem: Equatable, Identifiable {
    var id = UUID()
    var name = ""
    var active = false
    var iconName: String?
    var controlType: ControlType = .Switch
    var onCommand: EvolutionCommand?
    var offCommand: EvolutionCommand?
    var singleCommand: EvolutionCommand?
    var statusCommand: EvolutionCommand?

    func doSwitch() {
        @Dependency(\.evolutionCommandService) var evolutionCommandService
        Task { @MainActor in
            if controlType == .Button {
                guard let singleCommand else { return }
                _ = try? await evolutionCommandService.executeCommand(singleCommand)
                _ = try? await displayNotificationCMD(
                    title: name,
                    content: "",
                    subtitle: "Running".localized()
                )
                .runAppleScript()
            } else {
                guard
                    let statusCommand,
                    let trueCondition = statusCommand.trueCondition,
                    let statusResult = try? await evolutionCommandService.executeCommand(statusCommand)
                else {
                    return
                }

                let isOn = trueCondition == statusResult
                let shouldTurnOn = !isOn
                if shouldTurnOn {
                    _ = try? await evolutionCommandService.executeCommand(onCommand)
                } else {
                    guard let offCommand else { return }
                    _ = try? await evolutionCommandService.executeCommand(offCommand)
                }
                _ = try? await displayNotificationCMD(
                    title: name,
                    content: "",
                    subtitle: shouldTurnOn ? "Turn off".localized() : "Turn on".localized()
                )
                .runAppleScript()
            }
            NotificationCenter.default.post(name: .changeSettings, object: nil)
        }
    }
}

struct EvolutionCommand: Equatable {
    var executeType: CommandExecuteType = .shell
    var commandType: CommandType
    var commandString: String = ""
    var debugStatus: CommandDebugStatus = .unknow
    var trueCondition: String?
}

enum CommandExecuteType: String, Equatable, Codable {
    case shell, applescript
}

enum CommandType: String, Codable {
    case on, off, single, status

    var typeTitle: String {
        switch self {
            case .on:
                return "Turn on".localized()

            case .off:
                return "Turn off".localized()

            case .single:
                return "Button".localized()

            case .status:
                return "Check status".localized()
        }
    }
}

enum CommandDebugStatus {
    case unknow, failed, success
}

enum EvolutionError: Error, Equatable {
    case noCommand
    case wrongCommand
    case deleteFailed
    case noneEntity
}


