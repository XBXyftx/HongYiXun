/**
 * 大图查看器组件
 * 支持双指缩放、拖动查看、保存图片
 */
import { promptAction } from "@kit.ArkUI"
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo } from '@kit.CoreFileKit'
import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct ImageViewer {
  @Param imageUrl: string = ''
  @Param visible: boolean = false
  @Event onClose: () => void = () => {}

  // 缩放和位置状态
  @Local imageScale: number = 1
  @Local offsetX: number = 0
  @Local offsetY: number = 0
  @Local lastScale: number = 1
  @Local lastOffsetX: number = 0
  @Local lastOffsetY: number = 0
  @Local isSaving: boolean = false

  // 缩放限制
  private minScale: number = 0.5
  private maxScale: number = 4

  resetState(): void {
    this.imageScale = 1
    this.offsetX = 0
    this.offsetY = 0
    this.lastScale = 1
    this.lastOffsetX = 0
    this.lastOffsetY = 0
  }

  close(): void {
    this.resetState()
    this.onClose()
  }

  async saveImage(): Promise<void> {
    if (this.isSaving) return
    this.isSaving = true

    try {
      // 判断是网络图片还是本地图片
      if (this.imageUrl.startsWith('http://') || this.imageUrl.startsWith('https://')) {
        await this.saveNetworkImage()
      } else {
        await this.saveLocalImage()
      }
    } catch (error) {
      const err = error as BusinessError
      promptAction.openToast({ message: `保存失败: ${err.message}`, duration: 1500 })
    } finally {
      this.isSaving = false
    }
  }

  async saveNetworkImage(): Promise<void> {
    // 下载网络图片
    const httpRequest = http.createHttp()
    const response = await httpRequest.request(this.imageUrl, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.ARRAY_BUFFER
    })

    if (response.responseCode === 200) {
      const imageData = response.result as ArrayBuffer
      await this.saveToGallery(imageData)
    } else {
      throw new Error('下载图片失败')
    }
    httpRequest.destroy()
  }

  async saveLocalImage(): Promise<void> {
    // 读取本地图片
    const file = fileIo.openSync(this.imageUrl, fileIo.OpenMode.READ_ONLY)
    const stat = fileIo.statSync(this.imageUrl)
    const buffer = new ArrayBuffer(stat.size)
    fileIo.readSync(file.fd, buffer)
    fileIo.closeSync(file)
    await this.saveToGallery(buffer)
  }

  async saveToGallery(imageData: ArrayBuffer): Promise<void> {
    // 获取相册访问权限并保存
    const context = getContext(this)
    const helper = photoAccessHelper.getPhotoAccessHelper(context)
    const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg')
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE)
    fileIo.writeSync(file.fd, imageData)
    fileIo.closeSync(file)
    promptAction.openToast({ message: '已保存到相册', duration: 1500 })
  }

  build() {
    Stack() {
      // 半透明背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.9)')
        .onClick(() => this.close())

      // 图片容器
      Column() {
        Image(this.imageUrl)
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
          .scale({ x: this.imageScale, y: this.imageScale })
          .translate({ x: this.offsetX, y: this.offsetY })
          .gesture(
            GestureGroup(GestureMode.Parallel,
              // 双指缩放
              PinchGesture({ fingers: 2 })
                .onActionStart(() => {
                  this.lastScale = this.imageScale
                })
                .onActionUpdate((event: GestureEvent) => {
                  const newScale = this.lastScale * event.scale
                  this.imageScale = Math.max(this.minScale, Math.min(this.maxScale, newScale))
                }),
              // 拖动 - 设置较小的触发距离使拖动更跟手
              PanGesture({ fingers: 1, distance: 1 })
                .onActionStart(() => {
                  this.lastOffsetX = this.offsetX
                  this.lastOffsetY = this.offsetY
                })
                .onActionUpdate((event: GestureEvent) => {
                  // 直接使用偏移量，不需要除以缩放比例
                  this.offsetX = this.lastOffsetX + event.offsetX
                  this.offsetY = this.lastOffsetY + event.offsetY
                })
            )
          )
      }
      .width('100%')
      .height('80%')

      // 顶部工具栏
      Row() {
        // 关闭按钮
        Image($rawfile('close.svg'))
          .width(28)
          .height(28)
          .fillColor(Color.White)
          .onClick(() => this.close())

        Blank()

        // 保存按钮
        Row() {
          if (this.isSaving) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Color.White)
          } else {
            Image($rawfile('download_icon.svg'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
          }
          Text(this.isSaving ? '保存中...' : '保存')
            .fontSize(14)
            .fontColor(Color.White)
            .margin({ left: 6 })
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.2)')
        .borderRadius(20)
        .onClick(() => this.saveImage())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 48, bottom: 16 })
      .position({ top: 0 })

      // 底部提示
      Text('双指缩放 · 单指拖动 · 点击背景关闭')
        .fontSize(12)
        .fontColor('rgba(255, 255, 255, 0.6)')
        .position({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .visibility(this.visible ? Visibility.Visible : Visibility.None)
    .position({ top: 0, left: 0 })
  }
}
