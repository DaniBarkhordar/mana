package com.example.pp_bluetooth_kit_flutter.util;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;


public class PermissionSettingUtil {

    public final static String EMUI = "huawei"; //华为
    public final static String Flyme = "meizu"; //魅族
    public final static String MIUI = "xiaomi"; //小米
    public final static String Sony = "sony"; //索尼
    public final static String ColorOS = "oppo"; //OPPO
    public final static String EUI = "letv"; //乐视
    public final static String LG = "lg"; //LG
    public final static String SamSung = "samsung"; //三星
    public final static String SmartisanOS = "smartisan";//锤子
    public final static String VIVO = "vivo"; //VIVO
    public final static String Kupai = "yulong";
    public final static String ZTE = "zte";
    public final static String LENOVO = "lenovo";

    /**
     * 跳转至权限设置页面
     *
     * @param context
     * @return
     */
    public static boolean gotoPermissionSetting(Context context) {
        boolean success = true;
        Intent intent = new Intent();
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        String packageName = context.getPackageName();
        String romType = Build.MANUFACTURER.toLowerCase();
        switch (romType) {
            case EMUI: // 华为
                intent.putExtra("packageName", packageName);
                intent.setComponent(new ComponentName("com.huawei.systemmanager", "com.huawei.permissionmanager.ui.MainActivity"));
                break;
            case Flyme: // 魅族
                intent.setAction("com.meizu.safe.security.SHOW_APPSEC");
                intent.addCategory(Intent.CATEGORY_DEFAULT);
                intent.putExtra("packageName", packageName);
                break;
            case MIUI: // 小米
                String rom = getMiuiVersion();
                if ("V6".equals(rom) || "V7".equals(rom) || "V5".equals(rom)) {
                    intent.setAction("miui.intent.action.APP_PERM_EDITOR");
                    intent.setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.AppPermissionsEditorActivity");
                    intent.putExtra("extra_pkgname", packageName);
                } else if ("V8".equals(rom) || "V9".equals(rom)) {
                    intent.setAction("miui.intent.action.APP_PERM_EDITOR");
                    intent.setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity");
                    intent.putExtra("extra_pkgname", packageName);
                } else {
                    intent = getAppDetailSettingIntent(context);
                }
                break;
            case Sony: // 索尼
                intent.putExtra("packageName", packageName);
                intent.setComponent(new ComponentName("com.sonymobile.cta", "com.sonymobile.cta.SomcCTAMainActivity"));
                break;
            case EUI: // 乐视
                intent.putExtra("packageName", packageName);
                intent.setComponent(new ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.PermissionAndApps"));
                break;
            case LG: // LG
                intent.setAction("android.intent.action.MAIN");
                intent.putExtra("packageName", packageName);
                ComponentName comp = new ComponentName("com.android.settings", "com.android.settings.Settings$AccessLockSummaryActivity");
                intent.setComponent(comp);
                break;
            case SamSung: // 三星
                intent = getAppDetailSettingIntent(context);
                break;
            case SmartisanOS: // 锤子
                intent = getAppDetailSettingIntent(context);
                break;
//            case VIVO:
//                intent = context.getPackageManager().getLaunchIntentForPackage("com.iqoo.secure");
//                break;
//            case ColorOS: // OPPO
//                intent = context.getPackageManager().getLaunchIntentForPackage("com.iqoo.secure");
////                intent.putExtra("packageName", packageName);
////                intent.setComponent(new ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.PermissionManagerActivity"));
//                break;
            default:
                intent = getAppDetailSettingIntent(context);
                break;
        }
        try {
            context.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
            // 跳转失败, 前往普通设置界面
            try {
                context.startActivity(getAppDetailSettingIntent(context));
            } catch (Exception e1) {
                context.startActivity(new Intent(Settings.ACTION_SETTINGS));
                e1.printStackTrace();
            }
        }
        return success;
    }

    private static String getMiuiVersion() {
        String propName = "ro.miui.ui.version.name";
        String line;
        BufferedReader input = null;
        try {
            Process p = Runtime.getRuntime().exec("getprop " + propName);
            input = new BufferedReader(
                new InputStreamReader(p.getInputStream()), 1024);
            line = input.readLine();
            input.close();
        } catch (IOException ex) {
            ex.printStackTrace();
            return null;
        } finally {
//            LshIOUtils.close(input);
        }
//        LshLogUtils.i("MiuiVersion = " + line);
        return line;
    }

    /**
     * 获取应用详情页面intent（如果找不到要跳转的界面，也可以先把用户引导到系统设置页面）
     *
     *  Go to your app's Settings page to let user turn on the necessary permissions.
     *
     * @return
     */
    private static Intent getAppDetailSettingIntent(Context context) {
        Intent localIntent = new Intent();
        localIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        localIntent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        localIntent.setData(Uri.fromParts("package", context.getPackageName(), null));
        return localIntent;
    }


    /**
     * 默认打开应用详细页
     */
    public static void goIntentSetting(Activity pActivity) {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        Uri uri = Uri.fromParts("package", pActivity.getPackageName(), null);
        intent.setData(uri);
        try {
            pActivity.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }



}
