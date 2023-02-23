//
//  main.swift
//  alac
//
//  Created by Gene Marks on 2/19/23.
//

import Foundation
import ArgumentParser
import Tqdm

enum AlacError: Error {
    case ffmpegNotInstalled
    case invalidFileOrFolder
    case noAudioFilesFound(String)
    case improperThreadsUsage
    case outsideThreadsRange
    case improperRecursiveUsage
    case conversionFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .ffmpegNotInstalled:
            return "Homebrew ffmpeg package not installed."
        case .invalidFileOrFolder:
            return "The specified file or folder is invalid."
        case .noAudioFilesFound(let fileType):
            return "The specified folder contains no .\(fileType) file/s."
        case .improperThreadsUsage:
            return "The --threads <threads> option can only be used on folders."
        case .outsideThreadsRange:
            return "Outside expected threads range. Only use a number 1 - 4."
        case .improperRecursiveUsage:
            return "The --recursive flag can only be used for folders."
        case .conversionFailed(let fileType):
            return "The conversion failed. Please check that your .\(fileType) files are valid."
        }
    }
}

struct Alac: ParsableCommand {
    @Argument(help: "File or folder to process.")
    var input: String
    
    @Option(help: "Number of jobs to run simultaneously (1 - 4).")
    var threads: Int = 1
    
    @Flag(help: "Process all flacs/m4as(alacs) in folder tree.")
    var recursive: Bool = false
    
    @Flag(help: "Convert .m4as(alacs) back to .flacs.")
    var revert: Bool = false
    
    func run() throws {
        do {
            let fileManager = FileManager.default
            
            let inputURL = URL(fileURLWithPath: input)
            guard fileManager.fileExists(atPath: inputURL.path) else {
                throw AlacError.invalidFileOrFolder
            }
            
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: inputURL.path, isDirectory: &isDirectory)
            
            if !isDirectory.boolValue {
                guard threads == 1 else {
                    throw AlacError.improperThreadsUsage
                }
                
                guard !recursive else {
                    throw AlacError.improperRecursiveUsage
                }
            }
            
            if isDirectory.boolValue {
                var fileURLs: [URL] = []
                
                if let enumerator = fileManager.enumerator(at: inputURL, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        fileURLs.append(fileURL)
                    }
                }
                
                fileURLs = fileURLs.filter { $0.pathExtension == (revert ? "m4a" : "flac") }
                
                if !recursive {
                    fileURLs = fileURLs.filter { fileURL in
                        return fileURL.deletingLastPathComponent() == inputURL
                    }
                }
                
                guard !fileURLs.isEmpty else {
                    throw AlacError.noAudioFilesFound(revert ? "m4a" : "flac")
                }
                
                guard (1...4).contains(threads) else {
                    throw AlacError.outsideThreadsRange
                }
                
                print("Converting \(revert ? "alac" : "flac") files to \(revert ? "flacs" : "alacs")...")
                let progress = Tqdm(total: fileURLs.count, columnCount: 50)
                
                
                if threads > 1 {
                    let chunkSize = fileURLs.count / threads
                    let remainder = fileURLs.count % threads

                    var startIndex = 0
                    var endIndex = chunkSize

                    let group = DispatchGroup()

                    for i in 0..<threads {
                        if i < remainder {
                            endIndex += 1
                        }

                        let chunk = Array(fileURLs[startIndex..<endIndex])

                        DispatchQueue.global().async(group: group) {
                            for url in chunk {
                                try? convert(inputURL: url)
                                progress.update()
                            }
                        }

                        startIndex = endIndex
                        endIndex += chunkSize
                    }

                    group.wait()

                } else {
                    for fileURL in fileURLs {
                        try convert(inputURL: fileURL)
                        progress.update()
                    }
                }
                
                progress.close()
                
            } else {
                guard inputURL.pathExtension == (revert ? "m4a" : "flac") else {
                    throw AlacError.invalidFileOrFolder
                }
                
                print("Converting \(revert ? "alac" : "flac") file to \(revert ? "flac" : "alac")...")
                try convert(inputURL: inputURL)
            }
        
            print("Done!")
            
        } catch let error as AlacError {
            print("Error: \(error.localizedDescription)")
        } catch {
            print("Unknown error: \(error)")
        }
    }

    func convert(inputURL: URL) throws {
        let fileManager = FileManager.default
        
        let ffmpegURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        guard fileManager.fileExists(atPath: ffmpegURL.path), try ffmpegURL.checkResourceIsReachable() else {
            throw AlacError.ffmpegNotInstalled
        }
        
        let outputURL = inputURL.deletingPathExtension().appendingPathExtension(revert ? "flac" : "m4a")

        let process = Process()
        process.executableURL = ffmpegURL
        
        let arguments = ["-nostdin", "-i", inputURL.path, "-c:v", "copy", "-c:a", revert ? "flac" : "alac", outputURL.path]
        process.arguments = arguments
        
        let nullDevice = FileHandle.nullDevice
        process.standardOutput = nullDevice
        process.standardError = nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to run ffmpeg: \(error)")
        }

        guard process.terminationStatus == 0, fileManager.fileExists(atPath: outputURL.path) else {
            throw AlacError.conversionFailed(revert ? "m4a" : "flac")
        }
        
        do {
            try fileManager.trashItem(at: inputURL, resultingItemURL: nil)
        } catch {
            print("Failed to move file to trash: \(error)")
        }
    }
}

Alac.main()
