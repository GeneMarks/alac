//
//  main.swift
//  alac
//
//  Created by Gene Marks on 2/19/23.
//

import Foundation
import ArgumentParser

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
    
    @Option(help: "Number of jobs to run simulataneously (1 - 4).")
    var threads: Int = 1
    
    @Flag(help: "Process all flacs/m4as(alacs) in folder tree.")
    var recursive: Bool = false
    
    @Flag(help: "Convert .m4as(alacs) back to .flacs.")
    var revert: Bool = false
    
    func run() throws {
        do {
            let fileManager = FileManager.default
            
            // Check if inputURL is a valid file/folder
            let inputURL = URL(fileURLWithPath: input)
            guard fileManager.fileExists(atPath: inputURL.path) else {
                throw AlacError.invalidFileOrFolder
            }
            
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: inputURL.path, isDirectory: &isDirectory)
            
            if !isDirectory.boolValue {
                // Check if threads option improperly used on a file
                guard threads == 1 else {
                    throw AlacError.improperThreadsUsage
                }
                
                // Check if recursive flag improperly used on a file
                guard !recursive else {
                    throw AlacError.improperRecursiveUsage
                }
            }
            
            if isDirectory.boolValue {
                var fileURLs: [URL] = []
                
                // Add all files recursively to array
                if let enumerator = fileManager.enumerator(at: inputURL, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        fileURLs.append(fileURL)
                    }
                }
                
                // Remove all non-audio files from arr
                fileURLs = fileURLs.filter { $0.pathExtension == (revert ? "m4a" : "flac") }
                
                // Keep only top level files if not recursive
                if !recursive {
                    fileURLs = fileURLs.filter { fileURL in
                        return fileURL.deletingLastPathComponent() == inputURL
                    }
                }
                
                // Check if arr isn't empty
                guard !fileURLs.isEmpty else {
                    throw AlacError.noAudioFilesFound(revert ? "m4a" : "flac")
                }
                
                // Check if threads option is a number 1 - 4
                guard (1...4).contains(threads) else {
                    throw AlacError.outsideThreadsRange
                }
                
                // Handle multi-threading
                if threads > 1 {
                    // Calculate the chunk size and remainder
                    let chunkSize = fileURLs.count / threads
                    let remainder = fileURLs.count % threads

                    // Keep track of the start and end indices of each chunk
                    var startIndex = 0
                    var endIndex = chunkSize

                    let group = DispatchGroup()

                    for i in 0..<threads {
                        // Adjust the end index if there is a remainder
                        if i < remainder {
                            endIndex += 1
                        }

                        // Extract the current chunk of file URLs
                        let chunk = Array(fileURLs[startIndex..<endIndex])

                        // Run the conversion process asynchronously on a global queue and add it to the DispatchGroup
                        DispatchQueue.global().async(group: group) {
                            for url in chunk {
                                try? convert(inputURL: url)
                            }
                        }

                        // Update the start and end indices for the next chunk
                        startIndex = endIndex
                        endIndex += chunkSize
                    }

                    group.wait()

                } else {
                    // Convert all audio files
                    for fileURL in fileURLs {
                        try convert(inputURL: fileURL)
                    }
                }
            } else {
                // Check if file is an audio file
                guard inputURL.pathExtension == (revert ? "m4a" : "flac") else {
                    throw AlacError.invalidFileOrFolder
                }
                
                // Convert audio file
                try convert(inputURL: inputURL)
            }
        } catch let error as AlacError {
            print("Error: \(error.localizedDescription)")
        } catch {
            print("Unknown error: \(error)")
        }
    }

    func convert(inputURL: URL) throws {
        let fileManager = FileManager.default
        
        // First, check if ffmpeg is installed
        let ffmpegURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        guard fileManager.fileExists(atPath: ffmpegURL.path), try ffmpegURL.checkResourceIsReachable() else {
            throw AlacError.ffmpegNotInstalled
        }
        
        let outputURL = inputURL.deletingPathExtension().appendingPathExtension(revert ? "flac" : "m4a")

        // Construct ffmpeg command
        let process = Process()
        process.executableURL = ffmpegURL
        let arguments = ["-nostdin", "-i", inputURL.path, "-c:v", "copy", "-c:a", revert ? "flac" : "alac", outputURL.path]
        process.arguments = arguments

        // Run the command and wait for it to finish
        print("Converting \(inputURL.path) to" + (revert ? " FLAC" : " ALAC") + "...")
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to run process: \(error)")
        }

        // Check if the conversion was "successful"
        guard process.terminationStatus == 0, fileManager.fileExists(atPath: outputURL.path) else {
            throw AlacError.conversionFailed(revert ? "m4a" : "flac")
        }
        
        // Move input file to trash
        print("Moving input" + (revert ? "alac" : "flac") + "to trash...")
        do {
            try fileManager.trashItem(at: inputURL, resultingItemURL: nil)
        } catch {
            print("Failed to move file to trash: \(error.localizedDescription)")
        }
    }
}

Alac.main()
