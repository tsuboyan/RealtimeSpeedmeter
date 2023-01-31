//
//  CSVService.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/28.
//

import Foundation

final class CSVService {
    func saveCSV(dataStr: String) {
        let now = Date()
        let formatter_csv = DateFormatter()
        formatter_csv.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = formatter_csv.string(from: now) + ".csv"
        saveCSV(fileName: fileName, dataStr: dataStr)
    }
    
    func saveCSV(fileName: String, dataStr: String) {
        if let documentDirectoryFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            let targetTextFilePath = documentDirectoryFileURL.appendingPathComponent(fileName)
            do {
                let stringToWrite = dataStr
                try stringToWrite.write(to: targetTextFilePath, atomically: true, encoding: String.Encoding.utf8)
            } catch let error {
                print("failed to append: \(error)")
            }
        }
    }
}
