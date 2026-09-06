//
//  PPLefuScaleTools.swift
//  Pods
//
//  Created by lefu on 2025/4/3
//  


import Foundation
import SSZipArchive

class PPLefuScaleTools {
    
    class func loadDFUZipFile(path: String) -> String?{
        
        guard let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {

            return nil
        }

        let zipPath = path
        let destinationPath =  cachePath + "/Torre"
        
        self.clearDirectoryContents(at: destinationPath) { success, error in
//            print("清空文件夹：\(success)")
        }

        let success = unzipFile(atPath: zipPath, toDestination: destinationPath)

        if success {

            return destinationPath
        } else {

            return nil
        }
    }
    
    class func unzipFile(atPath filePath: String, toDestination destinationPath: String) -> Bool {
        
        let success = SSZipArchive.unzipFile(atPath: filePath, toDestination: destinationPath)
              
        return success
    }
    
    
    class func clearDirectoryContents(
        at path: String,
        completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil
    ) {
        let fileManager = FileManager.default
        
        var operationError: Error?
        var success = false
        
        defer {
            // 确保回调到主线程
            DispatchQueue.main.async {
                completion?(success, operationError)
            }
        }
        
        // 2. 验证路径安全性（防止误操作系统文件）
        guard isSafePath(path) else {
            operationError = NSError(domain: "FilePathError", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "危险路径禁止操作"])
            return
        }
        
        // 3. 检查路径是否存在且是目录
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            operationError = NSError(domain: "FilePathError", code: -2,
                                   userInfo: [NSLocalizedDescriptionKey: "路径不存在或不是文件夹"])
            return
        }
        
        do {
            // 4. 获取目录内容（跳过隐藏文件）
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            // 5. 遍历删除每一项
            for item in contents {
                let itemPath = (path as NSString).appendingPathComponent(item)
                try? fileManager.removeItem(atPath: itemPath) // 忽略单个文件删除错误
            }
            
            success = true
        } catch {
            operationError = error
        }
    }

    /// 安全路径检查（防止误删系统文件）
    class private func isSafePath(_ path: String) -> Bool {
        let forbiddenPaths = ["/System", "/Library", "/usr", "/bin", "/sbin", "/var"]
        let home = NSHomeDirectory()
        
        // 只允许操作应用沙盒内或临时目录的文件
        return path.hasPrefix(home) ||
               path.hasPrefix(NSTemporaryDirectory()) ||
               !forbiddenPaths.contains { path.hasPrefix($0) }
    }
    
}
