package com.example.pp_bluetooth_kit_flutter.util;

public class ObjNull {

    public static boolean isNull(Object object) {
        return object == null;
    }

    public static boolean isNullThrow(Object object) {
        if (isNull(object)) {
            throw new NullPointerException();
        }
        return false;
    }
}
