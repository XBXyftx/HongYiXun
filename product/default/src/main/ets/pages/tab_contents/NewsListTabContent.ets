import { APP_STORAGE_KEYS, NewsArticle, NewsListHeaderIsSticky } from "common"
import { NewsList, newsManager, NewsSwiper } from "feature"
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
  async reloadAllData() {
    promptAction.openToast({ message: '刷新数据' })
    if (await newsManager.updateNewsListToDB() && await newsManager.updateNewsSwiperToDB()) {
      this.newsList = await newsManager.getNewsArticleListFromDB()
      this.newsSwiperData = await newsManager.getNewsSwiperDataFromDB()
      return true
    }
    promptAction.openToast({ message: '获取新数据失败请稍后再试。' })
    return false
  }
  build() {
    Refresh({ refreshing: $$this.isLoading }) {
      List({ space: 20, scroller: this.listScroller }) {
        ListItemGroup() {
          ListItem() {
            NewsSwiper({ swiperData: this.newsSwiperData ?? [] })
          }
        }

        NewsList({ newsList: this.newsList ?? [], listScroller: this.listScroller, navStuck: this.navPathStuck })
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