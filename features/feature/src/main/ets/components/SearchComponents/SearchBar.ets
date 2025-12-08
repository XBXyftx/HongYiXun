/**
 * 搜索栏组件
 * 点击后使用共享元素转场展开到搜索页面
 */
import { DEVICE_TYPES, APP_STORAGE_KEYS, NAV_DESTS } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { AppStorageV2 } from "@kit.ArkUI"

// 共享元素转场ID
export const SEARCH_BAR_SHARED_ID = 'search_bar_shared_element'

@ComponentV2
export struct SearchBar {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!

  build() {
    Row() {
      Image($r('app.media.search'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .fillColor($r('app.color.text_secondary'))
        .margin({ right: 8 })

      Text('搜索本地新闻...')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
    }
    .width('95%')
    .height(this.deviceType === DEVICE_TYPES.PHONE ? 44 : 52)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(22)
    .margin({ top: 8, bottom: 8 })
    .geometryTransition(SEARCH_BAR_SHARED_ID, { follow: true })
    .transition(TransitionEffect.OPACITY.animation({ duration: 350, curve: Curve.Friction }))
    .onClick(() => {
      this.navPathStuck.pushPath({
        name: NAV_DESTS.SEARCH
      })
    })
  }
}