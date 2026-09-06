import { Any, EventChannel } from '@ohos/flutter_ohos';

import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

export class PPLefuStreamHandler implements StreamHandler {
  event: EventSink | null = null;

  onListen(args: Any, events: EventSink): void {
    this.event = events;
  }

  onCancel(args: Any): void {
    this.event?.endOfStream();
    this.event = null;
  }

  success(data: Any) {
    if (this.event) {
      this.event.success(data);
    }
  }

  error(details: Any) {
    if (this.event) {
      this.event.error("HarmonyOS", "Err", details);
    }
  }
}