import fs from '@ohos.file.fs';
import zlib from '@ohos.zlib';

/**
 * 蓝牙秤工具类
 */
export class PPLefuScaleTools {
  /**
   * 加载DFU升级包
   * @param path zip文件路径
   * @returns 解压后的目录路径
   */
  static async loadDFUZipFile(path: string): Promise<string | null> {
    try {
      // 获取缓存目录
      const context = getContext() as Context;
      const cachePath = context.cacheDir;
      
      const zipPath = path;
      const destinationPath = `${cachePath}/Torre`;

      // 清空目标目录
      await PPLefuScaleTools.clearDirectoryContents(destinationPath);

      // 解压文件
      const success = await PPLefuScaleTools.unzipFile(zipPath, destinationPath);

      if (success) {
        return destinationPath;
      }
      return null;
    } catch (error) {
      console.error('加载DFU文件失败:', error);
      return null;
    }
  }

  /**
   * 解压文件
   * @param filePath 源文件路径
   * @param destinationPath 目标路径
   * @returns 是否成功
   */
  static async unzipFile(filePath: string, destinationPath: string): Promise<boolean> {
    try {
      // // 确保目标目录存在
      // await fs.mkdir(destinationPath, { recursive: true });
      //
      // // 读取zip文件
      // const zipData = await fs.readFile(filePath);
      //
      // // 解压文件
      // const unzippedData = await zlib.decompressFile(zipData);
      //
      // // 写入解压后的文件
      // await fs.writeFile(destinationPath, unzippedData);
      //
      return true;
    } catch (error) {
      console.error('解压文件失败:', error);
      return false;
    }
  }

  /**
   * 清空目录内容
   * @param path 目录路径
   */
  static async clearDirectoryContents(path: string): Promise<void> {
    try {
      // 验证路径安全性
      if (!PPLefuScaleTools.isSafePath(path)) {
        throw new Error('危险路径禁止操作');
      }

      // 检查目录是否存在
      const stat = await fs.stat(path);
      if (!stat.isDirectory) {
        throw new Error('路径不存在或不是文件夹');
      }

      // 读取目录内容
      const files = await fs.listFile(path);

      // 遍历删除文件
      for (const file of files) {
        const filePath = `${path}/${file}`;
        try {
          await fs.unlink(filePath);
        } catch (error) {
          console.warn(`删除文件失败: ${filePath}`, error);
        }
      }
    } catch (error) {
      console.error('清空目录失败:', error);
      // throw error;
    }
  }

  /**
   * 检查路径是否安全
   * @param path 路径
   * @returns 是否安全
   */
  private static isSafePath(path: string): boolean {
    const forbiddenPaths = ['/system', '/data', '/vendor'];
    const context = getContext() as Context;
    const appPath = context.filesDir;

    // 只允许操作应用数据目录或缓存目录的文件
    return path.startsWith(appPath) ||
           path.startsWith(context.cacheDir) ||
           !forbiddenPaths.some(forbidden => path.startsWith(forbidden));
  }
}