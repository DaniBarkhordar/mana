import { ble } from '@kit.ConnectivityKit';
import { PPBaseDeviceControl } from '../PPBaseDeviceControl';
import { PPLogger } from '../../log/PPLogger';
import { BleUUID } from '../BleUUID';
import HexUtil from '../../utils/HexUtil';
import { ByteUtil } from '../../utils/ByteUtil';
import { UnitUtil } from '../../utils/UnitUtil';
import { PPUnitType } from '../../enums/PPUnitType';

import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { BusinessError } from '@kit.BasicServicesKit';

import { PPEggDeviceDataAnalysis } from './PPEggDeviceDataAnalysis';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';

/**
 * 连接 -> 连接中 -> 断开
 * 1、根据deviceID初始化gattClient实例，失败会有提示，业务可以做微调
 * 2、当前不同连接状态显示不同文字，连接/断开
 */

export class PPEggDeviceControl extends PPBaseDeviceControl {
  characteristicFFF1: ble.BLECharacteristic | null = null;
  dataChangeNotify?: (data: string) => void
  deviceInfoCharacteristics: ble.BLECharacteristic[] = [];
  characterBatteryUUID: ble.BLECharacteristic | null = null;
  dataAnalysis = new PPEggDeviceDataAnalysis();

  override onDiscoverServices(services: ble.GattService[]) {
    try {
      services.forEach(async service => {

        if (service.serviceUuid === BleUUID.SERVICE_MAIN) {

          // 获取服务下的所有特征
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_WRITE) {
              this.characteristicFFF1 = characteristic;
              PPLogger.i(`PPAppleDeviceControl onDiscoverServices targetWrite:${characteristic.characteristicUuid}`);
            } else if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
              PPLogger.i(`PPAppleDeviceControl onDiscoverServices targetNotify:${characteristic.characteristicUuid}`);
              // 订阅通知特征
              if (characteristic.properties?.notify) {
                await this.getGattClient()?.setCharacteristicChangeNotification(characteristic,
                  characteristic.properties?.notify);
              }
            }
          }
        } else if (service.serviceUuid === BleUUID.SERVICE_DEVICE_INFO) {
          this.deviceInfoCharacteristics = service.characteristics;
        } else if (service.serviceUuid === BleUUID.SERVICE_BATTERY) {
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_BATTERY_LEVEL) {
              PPLogger.i(`PPCoconutDeviceControl onDiscoverServices batteryReadUUID:${characteristic.characteristicUuid}`);
              this.characterBatteryUUID = characteristic;
            }
          }
        }
      });
      if (this.discoverServiceResultCallback) {
        this.discoverServiceResultCallback(true)
      }
    } catch (e) {
      if (this.discoverServiceResultCallback) {
        this.discoverServiceResultCallback(false)
      }
      PPLogger.e("onDiscoverServices fail msg:" + e)
    }
  }

  override OnCharacteristicReceived(characteristic: ble.BLECharacteristic) {
    let dataArray = new Uint8Array(characteristic.characteristicValue);
    let data: string = HexUtil.formatHexString(dataArray);
    if (this.dataChangeNotify) {
      this.dataChangeNotify(data);
    }
    if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
      PPLogger.i(`PPAppleDeviceControl OnCharacteristicReceived egg notify:${data}`);
      this.dataAnalysis.analysisData(dataArray, this.deviceModel ?? null);
    }
  }

  startNotify(dataChangeNotify?: (data: string) => void) {
    this.dataChangeNotify = dataChangeNotify;
  }




  async toZero(): Promise<boolean> {


    let byteArray = new Uint8Array(11); // Adjust size as needed
    let position = 0;


    // Start building the byte array
    byteArray[position++] = 0xFD; // Start byte

    // Add mode (converted from hex string to number)
    // let modeByte = parseInt(mode, 16);
    byteArray[position++] = 0x32;

    // Add unit
    byteArray[position++] = 0x00;

    // Add zeros
    byteArray[position++] = 0x00;

    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;

    // Calculate XOR
    let xor = 0;
    for (let i = 0; i < position; i++) {
      xor ^= byteArray[i];
    }

    // Add XOR byte
    byteArray[position++] = xor;

    // Slice the array to actual size
    let finalArray = byteArray.slice(0, position);

    return await this.writeResponseBytesF1(finalArray);
  }

  async buzzerGate(open:boolean): Promise<boolean> {


    let byteArray = new Uint8Array(11); // Adjust size as needed
    let position = 0;


    // Start building the byte array
    byteArray[position++] = 0xFD; // Start byte

    // Add mode (converted from hex string to number)
    // let modeByte = parseInt(mode, 16);
    byteArray[position++] = 0x41;

    // Add unit
    byteArray[position++] = open ? 0x01 : 0x00;

    // Add zeros
    byteArray[position++] = 0x00;

    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;

    // Calculate XOR
    let xor = 0;
    for (let i = 0; i < position; i++) {
      xor ^= byteArray[i];
    }

    // Add XOR byte
    byteArray[position++] = xor;

    // Slice the array to actual size
    let finalArray = byteArray.slice(0, position);

    return await this.writeResponseBytesF1(finalArray);
  }




  private buildTimeSyncCommand(milliseconds: number): Uint8Array {
    if (milliseconds <= 0) {
      return new Uint8Array(0);
    }
    //2025-09-08 10:55:02
    const date = new Date(milliseconds);
    const components = [
      date.getFullYear(), // 2字节
      date.getMonth() + 1, // 1字节
      date.getDate(), // 1字节
      date.getHours(), // 1字节
      date.getMinutes(), // 1字节
      date.getSeconds(),
      0// 1字节
    ];

    const commandHeader = ["FD","40"]

    // 转换各时间组件
    let timeBytes = components.map((comp, index) =>
    index === 0 ?  ByteUtil.decimalToHexLittleEndian(comp)  : ByteUtil.decimalToHexLittleEndian(comp));



    let timeHexStr = timeBytes.join("")


    let hex = ByteUtil.hexToBytes( commandHeader.join("") + timeBytes.join(""))

    let crc = ByteUtil.decimalToHexLittleEndian(this.crc16(hex))


    let hexStr =   commandHeader.join("") + timeHexStr + crc
    // 合并所有字节
    return ByteUtil.hexToBytes( hexStr)
  }

  crc16(data: Uint8Array): number {
    // 初始化CRC值为0xFFFF
    let crc: number = 0xFFFF;

    // 如果数据为空，直接返回初始值
    if (data.length === 0) {
      return crc;
    }

    // 第一个字节直接赋值给crc
    crc = data[0];

    // 从第二个字节开始，与当前crc进行异或运算
    for (let i = 1; i < data.length; i++) {
      const byte = data[i];
      crc = crc ^ byte;
    }

    // 返回16位无符号整数结果
    return crc & 0xFFFF;
  }

  // 最终调用方法
  async syncTime(milliseconds: number): Promise<boolean> {
    try {
      const command = this.buildTimeSyncCommand(milliseconds);

      let ss = ByteUtil.uint8ArrayToHex(command)
      if (command.length === 0) {
        return false;
      }

      return await this.writeResponseBytesF1(command);
    } catch (err) {
      PPLogger.e(`Time sync failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  async changeUnit(currentUnit: PPUnitType): Promise<boolean> {
    let byteArray = new Uint8Array(11); // Adjust size as needed
    let position = 0;
    let unit = 0;
    // 将当前单位数值转换为字符串

    let unitArray = this.deviceModel?.deviceUnitType?.split(",") ?? [];

    // 查找当前单位在数组中的索引
    let index: number = unitArray.indexOf(currentUnit.type.toString());

    // 计算下一个索引，超出范围则循环到开头
    let nextIndex: number = index + 1;
    if (nextIndex > unitArray.length - 1) {
      nextIndex = 0;
    }


    let nextUnit = UnitUtil.getUnitType(parseInt(unitArray[nextIndex]),this.deviceModel?.deviceName ?? "")

    if (this.deviceModel == null) {
      unit = UnitUtil.getUnitInt(nextUnit, "");
    } else {
      unit = UnitUtil.getUnitInt(nextUnit, this.deviceModel?.deviceName ?? "");
    }


    // Start building the byte array
    byteArray[position++] = 0xFD; // Start byte

    // Add mode (converted from hex string to number)
    // let modeByte = parseInt(mode, 16);
    byteArray[position++] = 0x00;

    // Add unit
    byteArray[position++] = unit;

    // Add zeros
    byteArray[position++] = 0x00;

    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;
    byteArray[position++] = 0x00;

    // Calculate XOR
    let xor = 0;
    for (let i = 0; i < position; i++) {
      xor ^= byteArray[i];
    }

    // Add XOR byte
    byteArray[position++] = xor;

    // Slice the array to actual size
    let finalArray = byteArray.slice(0, position);

    return await this.writeResponseBytesF1(finalArray);
  }



  // 读取设备信息
  async readDeviceInfo(): Promise<PPDeviceModel | null> {
    if (!this.deviceInfoCharacteristics) {
      PPLogger.e('DeviceController: No characteristics available');
      return null;
    }

    try {
      for (const characteristic of this.deviceInfoCharacteristics) {
        const charUUID = characteristic.characteristicUuid;

        // 统一使用安全读取方法
        const readData = async (): Promise<ArrayBuffer | null> => {
          try {
            const data = await this.getGattClient()?.readCharacteristicValue(characteristic);
            return data?.characteristicValue ?? null;
          } catch (e) {
            PPLogger.e(`Read characteristic ${charUUID} failed: ${JSON.stringify(e)}`);
            return null;
          }
        };

        switch (charUUID) {
          case BleUUID.CHARACTERISTIC_MODEL_NUMBER: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.modelNumber = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Model number - ${this.deviceModel.modelNumber}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_SOFTWARE_REV: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.softwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Software rev - ${this.deviceModel.softwareVersion}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_HARDWARE_REV: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.hardwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Hardware rev - ${this.deviceModel.hardwareVersion}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_FIRMWARE_REV: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.firmwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Firmware rev - ${this.deviceModel.firmwareVersion}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_SERIAL_NUMBER: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.serialNumber = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Serial number - ${this.deviceModel.serialNumber}`);
            }
            break;
          }
        }
      }
      return this.deviceModel;
    } catch (err) {
      PPLogger.e(`DeviceController: Error reading device info - ${JSON.stringify(err)}`);
      return null;
    }
  }

  /**
   * 读取设备电量
   * @returns 电量百分比（0-100），失败返回 -1
   */
  async readBatteryLevel(): Promise<number> {
    if (!this.characterBatteryUUID) {
      PPLogger.e('Battery characteristic not initialized');
      return -1;
    }

    try {
      // 1. 安全读取特征值（可能返回undefined）
      const dataCharacteristic = await this.getGattClient()?.readCharacteristicValue(this.characterBatteryUUID);

      const arrayBuffer = dataCharacteristic?.characteristicValue;

      // 2. 空值检查（处理undefined和空ArrayBuffer）
      if (!arrayBuffer || arrayBuffer.byteLength === 0) {
        PPLogger.e('Empty battery characteristic value');
        return -1;
      }

      // 3. 转换为Uint8Array读取数据
      const bytes = new Uint8Array(arrayBuffer);
      const batteryLevel = bytes[0];

      // 4. 验证范围（0-100）
      if (batteryLevel >= 0 && batteryLevel <= 100) {
        PPLogger.i(`Battery level: ${batteryLevel}%`);
        return batteryLevel;
      } else {
        PPLogger.e(`Invalid battery value: ${batteryLevel}`);
        return -1;
      }
    } catch (err) {
      PPLogger.e(`Read failed: ${JSON.stringify(err as BusinessError)}`);
      return -1;
    }
  }


  private async writeResponseBytesF1(bytes: Uint8Array): Promise<boolean> {
    if (!this.characteristicFFF1) {
      PPLogger.e(`PPAppleDeviceControl Characteristic FFF1 not initialized`);
      return false;
    }
    let writeFlag: boolean = false;
    let writeValue: ArrayBuffer = ByteUtil.typedArrayToBuffer(bytes);
    this.characteristicFFF1.characteristicValue = writeValue;
    PPLogger.e(`PPAppleDeviceControl Writing bytes: ${Array.from(bytes)}`);
    let errorMessage: string = ""
    let errorCode: string = ""
    try {
      await this.getGattClient()?.writeCharacteristicValue(this.characteristicFFF1, ble.GattWriteType.WRITE)
    } catch (e) {
      errorMessage = e.message;
      errorCode = e.code.toString()
      writeFlag = true;
    }
    if (writeFlag) {
      PPLogger.e(`PPAppleDeviceControl writeResponseBytesF1 errorcde: ${errorCode} ,  errmessage: ${errorMessage}`);
      return false;
    }
    PPLogger.d(`PPAppleDeviceControl Write success`);
    return true;
  }

  registerDataChangeListener(listener: PPDataChangeListener) {
    this.dataAnalysis.dataChangeListener = listener;
  }

  unRegisterDataChangeListener(): void {
    this.dataAnalysis.dataChangeListener = null
  }

}
