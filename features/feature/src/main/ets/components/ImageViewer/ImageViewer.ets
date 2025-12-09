/**
 * 大图查看器组件
 * 支持双指缩放、拖动查看、保存图片
 */
import { promptAction } from "@kit.ArkUI"
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo } from '@kit.CoreFileKit'
import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { logger, LOG_TAG } from 'common'

const TAG = LOG_TAG.IMAGE_VIEWER || '[ImageViewer]'

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
    if (this.isSaving) {
      logger.warn(`${TAG} 保存操作正在进行中，忽略重复点击`)
      return
    }
    this.isSaving = true
    logger.info(`${TAG} 开始保存图片: ${this.imageUrl}`)

    try {
      // 判断是网络图片还是本地图片
      if (this.imageUrl.startsWith('http://') || this.imageUrl.startsWith('https://')) {
        logger.info(`${TAG} 检测到网络图片，开始下载`)
        await this.saveNetworkImage()
      } else {
        logger.info(`${TAG} 检测到本地图片，开始读取`)
        await this.saveLocalImage()
      }
      logger.info(`${TAG} 图片保存成功`)
    } catch (error) {
      const err = error as BusinessError
      logger.error(`${TAG} 保存图片失败: code=${err.code}, message=${err.message}`)
      promptAction.openToast({ message: `保存失败: ${err.message}`, duration: 2000 })
    } finally {
      this.isSaving = false
    }
  }

  async saveNetworkImage(): Promise<void> {
    logger.info(`${TAG} 创建 HTTP 请求下载图片`)
    const httpRequest = http.createHttp()

    try {
      const response = await httpRequest.request(this.imageUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      })

      logger.info(`${TAG} HTTP 响应码: ${response.responseCode}`)

      if (response.responseCode === 200) {
        const imageData = response.result as ArrayBuffer
        logger.info(`${TAG} 图片下载成功，大小: ${imageData.byteLength} 字节`)
        await this.saveToGallery(imageData)
      } else {
        const errorMsg = `HTTP 请求失败，响应码: ${response.responseCode}`
        logger.error(`${TAG} ${errorMsg}`)
        throw new Error(errorMsg)
      }
    } finally {
      httpRequest.destroy()
      logger.info(`${TAG} HTTP 请求已销毁`)
    }
  }

  async saveLocalImage(): Promise<void> {
    logger.info(`${TAG} 开始读取本地图片: ${this.imageUrl}`)

    try {
      const stat = fileIo.statSync(this.imageUrl)
      logger.info(`${TAG} 文件大小: ${stat.size} 字节`)

      const file = fileIo.openSync(this.imageUrl, fileIo.OpenMode.READ_ONLY)
      logger.info(`${TAG} 文件已打开，fd: ${file.fd}`)

      const buffer = new ArrayBuffer(stat.size)
      const readBytes = fileIo.readSync(file.fd, buffer)
      logger.info(`${TAG} 已读取 ${readBytes} 字节`)

      fileIo.closeSync(file)
      logger.info(`${TAG} 本地文件已关闭`)

      await this.saveToGallery(buffer)
    } catch (error) {
      const err = error as BusinessError
      logger.error(`${TAG} 读取本地图片失败: code=${err.code}, message=${err.message}`)
      throw new Error(`读取本地图片失败: ${err.message}`)
    }
  }

  async saveToGallery(imageData: ArrayBuffer): Promise<void> {
    logger.info(`${TAG} 开始保存到相册，数据大小: ${imageData.byteLength} 字节`)

    try {
      const context = getContext(this) as common.UIAbilityContext
      logger.info(`${TAG} 获取上下文成功`)

      // 1. 先将图片保存到应用沙箱临时目录
      const tempFileName = `temp_image_${Date.now()}.jpg`
      const tempFilePath = `${context.cacheDir}/${tempFileName}`
      logger.info(`${TAG} 临时文件路径: ${tempFilePath}`)

      const tempFile = fileIo.openSync(tempFilePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      fileIo.writeSync(tempFile.fd, imageData)
      fileIo.closeSync(tempFile)
      logger.info(`${TAG} 临时文件已创建`)

      // 2. 使用 showAssetsCreationDialog 让用户确认保存到相册
      const helper = photoAccessHelper.getPhotoAccessHelper(context)
      logger.info(`${TAG} 获取 PhotoAccessHelper 成功`)

      const photoCreationConfigs: photoAccessHelper.PhotoCreationConfig[] = [{
        title: `image_${Date.now()}`,
        fileNameExtension: 'jpg',
        photoType: photoAccessHelper.PhotoType.IMAGE,
        subtype: photoAccessHelper.PhotoSubtype.DEFAULT
      }]
      logger.info(`${TAG} 准备调用 showAssetsCreationDialog`)

      // srcFileUris 是源文件 URI 数组，photoCreationConfigs 是创建配置数组
      const desFileUris = await helper.showAssetsCreationDialog([tempFilePath], photoCreationConfigs)
      logger.info(`${TAG} showAssetsCreationDialog 返回: ${JSON.stringify(desFileUris)}`)

      if (desFileUris.length === 0) {
        // 用户取消，删除临时文件
        fileIo.unlinkSync(tempFilePath)
        logger.warn(`${TAG} 用户取消保存，临时文件已删除`)
        promptAction.openToast({ message: '已取消保存', duration: 1500 })
        return
      }

      // 3. 将临时文件内容复制到目标 URI
      const desFileUri = desFileUris[0]
      logger.info(`${TAG} 目标 URI: ${desFileUri}`)

      // 读取临时文件
      const srcFile = fileIo.openSync(tempFilePath, fileIo.OpenMode.READ_ONLY)
      const srcStat = fileIo.statSync(tempFilePath)
      const srcBuffer = new ArrayBuffer(srcStat.size)
      fileIo.readSync(srcFile.fd, srcBuffer)
      fileIo.closeSync(srcFile)
      logger.info(`${TAG} 读取临时文件成功，大小: ${srcStat.size} 字节`)

      // 写入目标文件
      const desFile = fileIo.openSync(desFileUri, fileIo.OpenMode.WRITE_ONLY)
      const writtenBytes = fileIo.writeSync(desFile.fd, srcBuffer)
      fileIo.closeSync(desFile)
      logger.info(`${TAG} 写入目标文件成功，写入 ${writtenBytes} 字节`)

      // 4. 删除临时文件
      fileIo.unlinkSync(tempFilePath)
      logger.info(`${TAG} 临时文件已删除`)

      logger.info(`${TAG} 保存完成，目标 URI: ${desFileUri}`)
      promptAction.openToast({ message: '已保存到相册', duration: 1500 })
    } catch (error) {
      const err = error as BusinessError
      logger.error(`${TAG} 保存到相册失败: code=${err.code}, message=${err.message}`)
      throw new Error(`保存到相册失败: ${err.message}`)
    }
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
