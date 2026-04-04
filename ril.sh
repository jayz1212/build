#!/bin/bash


cd device/samsung/msm8916-common
git fetch https://github.com/jayz1212/android_device_samsung_msm8916-common-1.git patch-1
git cherry-pick ae2d8080142d1b4862c6ef51ab5e755a0556fc0d
cd - 


cd device/samsung/a5-common
git fetch https://github.com/jayz1212/android_device_samsung_a5-common.git patch-1
git cherry-pick e3427a6ba3592cd201efdf8f5359da9d9caa51fd
cd - 

cd device/samsung/a5ltechn
git fetch https://github.com/jayz1212/android_device_samsung_a5ltechn.git patch-1
git cherry-pick 5f126f96f5cd3c29c31cfd3390f14f923c99cbff
cd - 
