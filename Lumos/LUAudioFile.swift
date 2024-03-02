//
//  LUAudioFile.swift
//  Wavelength
//
//  Created by Manton Reece on 3/2/24.
//  Copyright © 2024 Jonathan Hays. All rights reserved.
//

import Foundation
import FFmpegSupport

@objc class LUAudioFile: NSObject {
	@objc static func convertToMP3(_ inputFile: String, outputFile: String) {
		ffmpeg(["ffmpeg", "-i", inputFile, outputFile])
	}
}
