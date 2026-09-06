///@author liyp
///@email liyp520@foxmail.com
///@date 2025/2/13 11:44
//@description

enum PPConfigWifiStateMenu {
  /**
   * 配网成功 Successful distribution network
   */
  CONFIG_STATE_SUCCESS,
  /**
   * 电量过低 Low battery level
   */
  CONFIG_STATE_LOW_BATTERY_LEVEL,
  /**
   * 注册失败 login has failed
   */
  CONFIG_STATE_REGIST_FAIL,
  /**
   * 获取配置失败 Failed to obtain configuration
   */
  CONFIG_STATE_GET_CONFIG_FAIL,
  /**
   * 找不到路由 Unable to find route
   */
  CONFIG_STATE_ROUTER_FAIL,
  /**
   * 密码错误 Password error
   */
  CONFIG_STATE_PASSWORD_ERR,
  /**
   * 其它错误（app可以不用关注）
   * Other errors (app can be ignored)
   */
  CONFIG_STATE_OTHER_FAIL,
}