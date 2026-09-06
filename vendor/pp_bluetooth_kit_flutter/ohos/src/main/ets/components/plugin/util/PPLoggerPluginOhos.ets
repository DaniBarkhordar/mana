// Logger.ets
import hilog from '@ohos.hilog';
import { PPLoggerListener } from 'ppsdkkit/src/main/ets/log/PPLoggerListener';


export class PPLoggerPluginOhos {
  private static listener: PPLoggerListener | null = null;
  private static tag: string = "PPLoggerPluginOhos"
  private static debug = true

  public addListener(listener: PPLoggerListener): void {
    PPLoggerPluginOhos.listener = listener;
  }

  public static setDebug(debug: boolean) {
    PPLoggerPluginOhos.debug = debug;
  }

  public static cancleListener(): void {
    PPLoggerPluginOhos.listener = null;
  }

  public static d(msg: string): void {
    PPLoggerPluginOhos.listener?.d?.(msg);
    if (PPLoggerPluginOhos.debug) {
      hilog.debug(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
    }
  }

  public static e(msg: string): void {
    PPLoggerPluginOhos.listener?.e?.(msg);
    hilog.error(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
  }

  public static i(msg: string): void {
    PPLoggerPluginOhos.listener?.i?.(msg);
    if (PPLoggerPluginOhos.debug) {
      hilog.info(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
    }
  }

  public static w(msg: string): void {
    PPLoggerPluginOhos.listener?.w?.(msg);
    hilog.warn(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
  }

  public static v(msg: string): void {
    PPLoggerPluginOhos.listener?.d?.(msg);
    if (PPLoggerPluginOhos.debug) {
      hilog.debug(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
    }
  }

  public static m(msg: string): void {
    const MAX_LINE_LENGTH = 1024; // 单行最大长度限制（建议值）

    // 1. 通知监听器（保持原样）
    PPLoggerPluginOhos.listener?.d?.(msg);

    // 2. 调试模式下处理长消息
    if (PPLoggerPluginOhos.debug) {
      if (msg.length <= MAX_LINE_LENGTH) {
        // 短消息直接打印
        hilog.debug(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
      } else {
        // 长消息分段打印
        let start = 0;
        let segment = 1;
        while (start < msg.length) {
          const end = Math.min(start + MAX_LINE_LENGTH, msg.length);
          const chunk = msg.substring(start, end);
          hilog.debug(0x0000, PPLoggerPluginOhos.tag,
            "[%d/%d] %{public}s",
            segment,
            Math.ceil(msg.length / MAX_LINE_LENGTH),
            chunk);
          start = end;
          segment++;
        }
      }
    }
  }


}