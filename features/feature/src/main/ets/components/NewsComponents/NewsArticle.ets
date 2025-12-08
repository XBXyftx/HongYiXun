/**
 * Copyright (c) 2025 XBXyftx
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import {
  CONTENT_TYPE_ENUM, DEVICE_TYPES, NewsArticle, NewsContentBlock, logger, LOG_TAG
} from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { LvMarkdownIn } from '@luvi/lv-markdown-in'
import { historyManager } from '../../managers/HistoryManager'

/**
 * 代码块预处理工具
 * 将原始代码转换为规范的 Markdown 代码块格式
 */
function preprocessCodeBlock(code: string): string {
  // 去除首尾空白
  let cleanCode = code.trim()

  // 如果已经是 Markdown 代码块格式，直接返回
  if (cleanCode.startsWith('```') && cleanCode.endsWith('```')) {
    return cleanCode
  }

  // 如果代码没有换行符，尝试智能添加换行
  if (!cleanCode.includes('\n')) {
    cleanCode = formatCompressedCode(cleanCode)
  }

  // 尝试检测代码语言
  const language = detectCodeLanguage(cleanCode)

  // 包装成 Markdown 代码块
  return '```' + language + '\n' + cleanCode + '\n```'
}

/**
 * 格式化压缩的代码，智能添加换行
 */
function formatCompressedCode(code: string): string {
  let result = code

  // 在 { 后添加换行（但不在 ${ 后）
  result = result.replace(/\{(?!\{)/g, '{\n')

  // 在 } 前添加换行（但不在 }} 前）
  result = result.replace(/(?<!\})(\})/g, '\n$1')

  // 在 ; 后添加换行（但不在字符串内）
  result = result.replace(/;(?=\s*[a-zA-Z_])/g, ';\n')

  // 在 C/C++ 风格的函数定义后添加换行
  result = result.replace(/\)\s*\{/g, ')\n{')

  // 在 return 语句前添加换行
  result = result.replace(/([^;\n])\s*(return\s)/g, '$1\n$2')

  // 在 if/else/for/while 前添加换行
  result = result.replace(/([;}])\s*(if\s*\(|else\s*\{|else\s+if|for\s*\(|while\s*\()/g, '$1\n$2')

  // 在 void/int/bool 等类型声明前添加换行（函数定义）
  result = result.replace(/([;}])\s*(void\s+|int\s+|int32_t\s+|bool\s+|char\s+|double\s+|float\s+|auto\s+)/g, '$1\n$2')

  // 清理多余的空行
  result = result.replace(/\n\s*\n\s*\n/g, '\n\n')

  // 清理行首空白
  const lines = result.split('\n')
  const formattedLines: string[] = []
  let indentLevel = 0

  for (const line of lines) {
    const trimmedLine = line.trim()
    if (trimmedLine.length === 0) {
      formattedLines.push('')
      continue
    }

    // 减少缩进（遇到 }）
    if (trimmedLine.startsWith('}')) {
      indentLevel = Math.max(0, indentLevel - 1)
    }

    // 添加缩进
    const indent = '    '.repeat(indentLevel)
    formattedLines.push(indent + trimmedLine)

    // 增加缩进（遇到 {）
    if (trimmedLine.endsWith('{')) {
      indentLevel++
    }
  }

  return formattedLines.join('\n')
}

/**
 * 检测代码语言
 */
function detectCodeLanguage(code: string): string {
  // C/C++ 特征
  if (code.includes('#include') || code.includes('std::') || code.includes('::') ||
      code.includes('void ') || code.includes('int32_t') || code.includes('nullptr')) {
    return 'cpp'
  }
  // Java 特征
  if (code.includes('public class') || code.includes('private void') ||
      code.includes('System.out') || code.includes('import java.')) {
    return 'java'
  }
  // JavaScript/TypeScript 特征
  if (code.includes('function ') || code.includes('const ') || code.includes('let ') ||
      code.includes('=>') || code.includes('console.log')) {
    if (code.includes(': string') || code.includes(': number') || code.includes('interface ')) {
      return 'typescript'
    }
    return 'javascript'
  }
  // Python 特征
  if (code.includes('def ') || code.includes('import ') || code.includes('print(') ||
      code.includes('self.') || code.includes('__init__')) {
    return 'python'
  }
  // JSON 特征
  if ((code.startsWith('{') && code.endsWith('}')) || (code.startsWith('[') && code.endsWith(']'))) {
    try {
      JSON.parse(code)
      return 'json'
    } catch (e) {
      // 不是有效 JSON
    }
  }
  // XML/HTML 特征
  if (code.includes('</') && code.includes('>')) {
    return 'xml'
  }
  // Shell 特征
  if (code.startsWith('#!/') || code.includes('echo ') || code.includes('$ ')) {
    return 'bash'
  }
  // 默认不指定语言
  return ''
}

/**
 * 合并连续的代码块
 * 将多个连续的 CODE 类型内容块合并为一个
 */
function mergeConsecutiveCodeBlocks(content: NewsContentBlock[]): NewsContentBlock[] {
  if (!content || content.length === 0) {
    return []
  }

  const result: NewsContentBlock[] = []
  let currentCodeLines: string[] = []

  for (let i = 0; i < content.length; i++) {
    const item = content[i]

    if (item.type === CONTENT_TYPE_ENUM.CODE) {
      // 收集代码行
      currentCodeLines.push(item.value)
    } else {
      // 遇到非代码块，先输出之前收集的代码
      if (currentCodeLines.length > 0) {
        result.push({
          type: CONTENT_TYPE_ENUM.CODE,
          value: currentCodeLines.join('\n')
        })
        currentCodeLines = []
      }
      // 输出当前非代码内容
      result.push(item)
    }
  }

  // 处理末尾的代码块
  if (currentCodeLines.length > 0) {
    result.push({
      type: CONTENT_TYPE_ENUM.CODE,
      value: currentCodeLines.join('\n')
    })
  }

  return result
}

/**
 * 文章内容渲染组件
 * @param article 带渲染文章内容
 * @param baseFontSize 基准字体大小
 */
@ComponentV2
export struct NewsArticleView {
  @Param article: NewsArticle = {
    id: "",
    title: "",
    date: "",
    url: "",
    content: [],
    source: ''
  }
  @Param baseFontSize: number = 0
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local processedContent: NewsContentBlock[] = []

  async aboutToAppear(): Promise<void> {
    // 合并连续的代码块
    this.processedContent = mergeConsecutiveCodeBlocks(this.article.content)

    // 添加浏览历史记录
    try {
      const success = await historyManager.addHistory(this.article)
      if (success) {
        logger.info(`${LOG_TAG.NEWS_LIST}添加浏览历史成功: ${this.article.title}`)
      }
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_LIST}添加浏览历史失败: ${JSON.stringify(error)}`)
    }
  }

  @Builder
  articleInfoBuilder() {
    Row() {
      Text(`日期：${this.article.date} ${this.article.source ? '来源：' : ''}${this.article.source}`)
        .fontSize(this.baseFontSize+(this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12))
    }
    .alignSelf(ItemAlign.Start)
    .width('95%')
  }

  build() {
    // 根组件
    Scroll() {
      Column({space:10+(this.baseFontSize*(this.deviceType === DEVICE_TYPES.PHONE ?0.3:0.5))}) {
        Text(this.article.title)
          .width('95%')
          .fontSize(this.baseFontSize + (this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16))
          .fontWeight(900)
          .alignSelf(ItemAlign.Center)
        // 日期来源行
        this.articleInfoBuilder()

        ForEach(this.processedContent, (item: NewsContentBlock, index: number) => {
          if (item.type === CONTENT_TYPE_ENUM.TEXT) {
            Text(`        ${item.value}`)
              .fontSize(this.baseFontSize+ (this.deviceType === DEVICE_TYPES.PHONE ? 0 : 6))
              .width('90%')
              .alignSelf(ItemAlign.Center)
          } else if (item.type === CONTENT_TYPE_ENUM.IMAGE) {
            Image(item.value)
              .width('90%')
              .alignSelf(ItemAlign.Center)
          } else if (item.type === CONTENT_TYPE_ENUM.VIDEO) {
            Video({
              src: item.value
            })
              .width('90%')
              .alignSelf(ItemAlign.Center)
          } else if (item.type === CONTENT_TYPE_ENUM.CODE) {
            LvMarkdownIn({
              text: preprocessCodeBlock(item.value)
            })
              .width('90%')
              .alignSelf(ItemAlign.Center)
          }
        }, (item: NewsContentBlock, index: number) => `${item.type}_${index}`)
      }
      .padding(5)
      .borderRadius(20)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor($r('app.color.article_info_builder_bg'))

    }
    .scrollBar(BarState.Off)
    .borderRadius(20)
    .width('100%')
    .height('100%')

  }
}