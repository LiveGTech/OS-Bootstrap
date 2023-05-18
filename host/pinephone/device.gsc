{
    "type": "mobile",
    "platform": "pinephone",
    "model": {
        "codename": "pinephone",
        "fallbackLocale": "en_GB",
        "name": {
            "en_GB": "PinePhone"
        },
        "manufacturer": {
            "en_GB": "PINE64"
        }
    },
    "hardware": {
        "batteryStateReporter": "/sys/class/power_supply/axp20x-battery/status",
        "batteryStateMapping": {
            "Charging": "charging",
            "Discharging": "discharging",
            "Not charging": "notCharging",
            "Full": "full"
        },
        "batteryLevelReporter": "/sys/class/power_supply/axp20x-battery/capacity"
    },
    "display": {
        "scaleFactor": 2
    }
}