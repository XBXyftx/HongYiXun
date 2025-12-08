import { APP_STORAGE_KEYS, NewsArticle, NewsListHeaderIsSticky, logger, LOG_TAG } from "common"
import { NewsList, newsManager, NewsSwiper, SearchBar } from "feature"
import { AppStorageV2, promptAction } from "@kit.ArkUI"

@ComponentV2
export struct NewsListTabContent{
  @Local isLoading: boolean = false
  @Local newsSwiperData: ResourceStr[] | null = []
  @Local newsList: NewsArticle[] | null = null
  @Local listScroller: Scroller = new Scroller()
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local isNewsListSticky: NewsListHeaderIsSticky =
    AppStorageV2.connect(NewsListHeaderIsSticky, APP_STORAGE_KEYS.IS_STICKY, () => new NewsListHeaderIsSticky())!
  // 用于触发 NewsList 组件的数据重新加载
  @Local refreshTrigger: number = 0
  async aboutToAppear(): Promise<void> {
    this.newsList = await newsManager.getNewsArticleListFromDB()
    if (!this.newsList) {
      promptAction.openToast({ message: `当前数据库新闻数据为空,请连接后端服务以更新数据` })
    } else if (this.newsList) {
      promptAction.openToast({ message: `从数据库查询到${this.newsList.length}条新闻数据` })
    }
    this.newsSwiperData = await newsManager.getNewsSwiperDataFromDB()
    if (!this.newsSwiperData) {
      promptAction.openToast({ message: `当前数据库轮播图数据为空,请连接后端服务以更新数据` })
    } else if (this.newsSwiperData) {
      promptAction.openToast({ message: `从数据库查询到${this.newsSwiperData.length}条轮播图数据` })
    }
  }
  /**
   * 两阶段刷新数据
   * 
   * 第一阶段：快速加载各分栏前20条 + 轮播图，立即结束刷新动画
   * 第二阶段：后台完整加载全部数据，实时更新 UI
   * 
   * @returns Promise<boolean> - 第一阶段是否成功
   */
  async reloadAllData(): Promise<boolean> {
    logger.info(`${LOG_TAG.NEWS_LIST}[两阶段刷新] 开始刷新`)
    promptAction.openToast({ message: '正在快速刷新最新数据...', duration: 1500 })

    try {
      // ========== 第一阶段：快速刷新（并发加载前20条） ==========
      const quickResult = await newsManager.quickRefreshCategories()

      if (quickResult.success) {
        // 刷新成功，重新加载轮播图数据
        this.newsSwiperData = await newsManager.getNewsSwiperDataFromDB()
        
        // 触发 NewsList 组件重新加载分类数据
        this.refreshTrigger++
        
        logger.info(`${LOG_TAG.NEWS_LIST}[两阶段刷新] ✓ 第一阶段完成: ${quickResult.loadedCount}个栏目`)
        promptAction.openToast({ 
          message: `刷新成功，已更新${quickResult.loadedCount}个栏目`, 
          duration: 2000 
        })

        // ========== 第二阶段：后台完整刷新（逐个加载全部数据） ==========
        // 不阻塞 UI，在后台执行
        newsManager.fullRefreshCategories((progress) => {
          logger.debug(`${LOG_TAG.NEWS_LIST}[两阶段刷新] [${progress.current}/${progress.total}] 【${progress.category}】完成`)
          
          // 每个栏目完成后触发 UI 更新
          this.refreshTrigger++
          
        }).then((fullResult) => {
          if (fullResult.success) {
            logger.info(`${LOG_TAG.NEWS_LIST}[两阶段刷新] ✓ 第二阶段完成: ${fullResult.updatedCount}个栏目`)
            promptAction.openToast({ 
              message: `后台更新完成，所有数据已是最新`, 
              duration: 2000 
            })
            
            // 最后一次触发更新
            this.refreshTrigger++
          } else {
            logger.warn(`${LOG_TAG.NEWS_LIST}[两阶段刷新] 第二阶段部分失败`)
          }
        }).catch((error: Error) => {
          logger.error(`${LOG_TAG.NEWS_LIST}[两阶段刷新] 第二阶段异常: ${error.message}`)
        })

        return true
      } else {
        logger.error(`${LOG_TAG.NEWS_LIST}[两阶段刷新] 第一阶段失败`)
        promptAction.openToast({ message: '刷新失败，请检查网络连接', duration: 2000 })
        return false
      }

    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_LIST}[两阶段刷新] 异常: ${JSON.stringify(error)}`)
      promptAction.openToast({ message: '刷新失败，请稍后再试', duration: 2000 })
      return false
    }
  }
  build() {
    Refresh({ refreshing: $$this.isLoading }) {
      List({ space: 20, scroller: this.listScroller }) {
        ListItemGroup() {
          ListItem() {
            Column() {
              SearchBar()
              NewsSwiper({ swiperData: this.newsSwiperData ?? [] })
            }
            .width('100%')
          }
        }

        NewsList({ 
          newsList: this.newsList ?? [], 
          listScroller: this.listScroller, 
          navStuck: this.navPathStuck,
          refreshTrigger: this.refreshTrigger 
        })
      }
      .expandSafeArea()
      .onReachStart(() => {
        this.isNewsListSticky.isSticky = false
      })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .chainAnimation(true)
      .sticky(StickyStyle.Header)
      .width('100%')
      .height('100%')
    }
    .expandSafeArea()
    .onRefreshing(async () => {
      await this.reloadAllData()
      this.isLoading = false
    })
  }
}