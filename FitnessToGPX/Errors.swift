//
//  Errors.swift
//  FitnessToGPX
//
//  Created by Sergej Jaskiewicz on 03.02.2022.
//

func HealthKitContractViolation(file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("HealthKit contract violation", file: file, line: line)
}
