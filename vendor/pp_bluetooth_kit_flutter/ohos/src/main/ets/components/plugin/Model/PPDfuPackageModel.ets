/**
 * DFU包模型
 */
export class PPDfuPackageModel {
  deviceSource: string;
  packageVersion: string;
  packages: PPDfuPackages;

  constructor(deviceSource: string, packageVersion: string, packages: PPDfuPackages) {
    this.deviceSource = deviceSource;
    this.packageVersion = packageVersion;
    this.packages = packages;
  }
}

/**
 * DFU包信息
 */
export class PPDfuPackages {
  mcu: PPDfuPackageInfo | null;
  ble: PPDfuPackageInfo | null;
  res: PPDfuPackageInfo | null;

  constructor(mcu?: PPDfuPackageInfo, ble?: PPDfuPackageInfo, res?: PPDfuPackageInfo) {
    this.mcu = mcu || null;
    this.ble = ble || null;
    this.res = res || null;
  }
}

/**
 * DFU包详细信息
 */
export class PPDfuPackageInfo {
  filename: string;
  version: string;

  constructor(filename: string, version: string) {
    this.filename = filename;
    this.version = version;
  }
}