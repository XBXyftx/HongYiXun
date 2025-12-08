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
import { common, Want } from '@kit.AbilityKit'

/**
 * 文本片段类型
 */
interface TextSegment {
  type: 'text' | 'link'
  content: string
  url?: string
}

/**
 * 解析文本中的链接
 * 将文本拆分为普通文本和链接片段
 */
function parseTextWithLinks(text: string): TextSegment[] {
  const segments: TextSegment[] = []
  // URL 正则表达式，匹配 http/https 链接
  const urlRegex = /(https?:\/\/[^\s<>"{}|\\^`\[\]]+)/g

  let lastIndex = 0
  let match: RegExpExecArray | null

  while ((match = urlRegex.exec(text)) !== null) {
    // 添加链接前的普通文本
    if (match.index > lastIndex) {
      segments.push({
        type: 'text',
        content: text.substring(lastIndex, match.index)
      })
    }

    // 添加链接
    segments.push({
      type: 'link',
      content: match[1],
      url: match[1]
    })

    lastIndex = match.index + match[0].length
  }

  // 添加最后的普通文本
  if (lastIndex < text.length) {
    segments.push({
      type: 'text',
      content: text.substring(lastIndex)
    })
  }

  // 如果没有找到链接，返回原始文本
  if (segments.length === 0) {
    segments.push({
      type: 'text',
      content: text
    })
  }

  return segments
}

/**
 * 检查文本是否包含链接
 */
function containsLink(text: string): boolean {
  const urlRegex = /https?:\/\/[^\s<>"{}|\\^`\[\]]+/
  return urlRegex.test(text)
}

/**
 * 打开外部链接
 */
function openExternalLink(url: string, context: common.UIAbilityContext): void {
  try {
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: url
    }
    context.startAbility(want)
  } catch (error) {
    logger.error(`${LOG_TAG.NEWS_LIST}打开链接失败: ${JSON.stringify(error)}`)
  }
}

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
 * 支持多种编程语言：C/C++, Java, JavaScript, TypeScript, Python, Go, Rust, C#, PHP, Swift, Kotlin 等
 */
function formatCompressedCode(code: string): string {
  let result = code

  // ========== 通用语句分隔符处理 ==========
  // 在分号后添加换行（C系语言通用）
  result = result.replace(/;(?!\s*$)/g, ';\n')

  // ========== 花括号处理（C系语言通用）==========
  // 在 { 后添加换行
  result = result.replace(/\{(?!\{|\s*\n)/g, '{\n')
  // 在 } 后添加换行（除非后面是 else, catch, finally, while 等）
  result = result.replace(/\}(?!\s*(else|catch|finally|while|,|\)|;|\]))/g, '}\n')
  // 在 } 前添加换行
  result = result.replace(/([^\n\s])\s*\}/g, '$1\n}')

  // ========== 控制流关键字处理 ==========
  // if/else/for/while/switch/case/do/try/catch/finally
  const controlKeywords = ['if', 'else', 'for', 'while', 'switch', 'case', 'default', 'do', 'try', 'catch', 'finally']
  for (const keyword of controlKeywords) {
    const regex = new RegExp(`([;{}])\\s*(${keyword}[\\s(])`, 'g')
    result = result.replace(regex, '$1\n$2')
  }

  // ========== 函数/方法定义处理 ==========
  // C/C++/Java/C#/Go/Rust 等类型声明
  const typeKeywords = [
    'void', 'int', 'int8_t', 'int16_t', 'int32_t', 'int64_t',
    'uint8_t', 'uint16_t', 'uint32_t', 'uint64_t',
    'bool', 'char', 'wchar_t', 'double', 'float', 'long', 'short',
    'auto', 'var', 'let', 'const', 'static', 'public', 'private', 'protected',
    'class', 'struct', 'enum', 'interface', 'namespace', 'using',
    'func', 'fn', 'def', 'function', 'async', 'await',
    'return', 'throw', 'new', 'delete', 'import', 'export', 'from',
    'package', 'module', 'require', 'include', 'extends', 'implements'
  ]
  for (const keyword of typeKeywords) {
    const regex = new RegExp(`([;{}])\\s*(${keyword}\\s+)`, 'g')
    result = result.replace(regex, '$1\n$2')
  }

  // ========== Python 特殊处理 ==========
  // Python 的冒号后换行（def, class, if, for, while, try, except, with 等）
  result = result.replace(/(def\s+\w+\s*\([^)]*\)\s*):/g, '$1:\n')
  result = result.replace(/(class\s+\w+[^:]*)\s*:/g, '$1:\n')
  result = result.replace(/(if\s+[^:]+)\s*:/g, '$1:\n')
  result = result.replace(/(elif\s+[^:]+)\s*:/g, '$1:\n')
  result = result.replace(/(else)\s*:/g, '$1:\n')
  result = result.replace(/(for\s+[^:]+)\s*:/g, '$1:\n')
  result = result.replace(/(while\s+[^:]+)\s*:/g, '$1:\n')
  result = result.replace(/(try)\s*:/g, '$1:\n')
  result = result.replace(/(except[^:]*)\s*:/g, '$1:\n')
  result = result.replace(/(finally)\s*:/g, '$1:\n')
  result = result.replace(/(with\s+[^:]+)\s*:/g, '$1:\n')

  // ========== Go 特殊处理 ==========
  result = result.replace(/(func\s+[^{]+)\s*\{/g, '$1 {\n')
  result = result.replace(/(type\s+\w+\s+struct)\s*\{/g, '$1 {\n')
  result = result.replace(/(type\s+\w+\s+interface)\s*\{/g, '$1 {\n')

  // ========== Rust 特殊处理 ==========
  result = result.replace(/(fn\s+\w+[^{]+)\s*\{/g, '$1 {\n')
  result = result.replace(/(impl[^{]+)\s*\{/g, '$1 {\n')
  result = result.replace(/(match\s+[^{]+)\s*\{/g, '$1 {\n')

  // ========== 箭头函数处理（JS/TS）==========
  result = result.replace(/(=>\s*)\{/g, '$1{\n')

  // ========== 注释处理 ==========
  // 单行注释后换行
  result = result.replace(/(\/\/[^\n]*)/g, '$1\n')
  // 多行注释后换行
  result = result.replace(/(\*\/)/g, '$1\n')

  // ========== 预处理指令（C/C++）==========
  result = result.replace(/(#\w+[^\n]*)/g, '$1\n')

  // ========== 清理和缩进 ==========
  // 清理多余的空行和空格
  result = result.replace(/\n\s*\n\s*\n/g, '\n\n')
  result = result.replace(/\n{3,}/g, '\n\n')

  // 智能缩进
  return applySmartIndent(result)
}

/**
 * 应用智能缩进
 */
function applySmartIndent(code: string): string {
  const lines = code.split('\n')
  const formattedLines: string[] = []
  let indentLevel = 0

  for (const line of lines) {
    const trimmedLine = line.trim()
    if (trimmedLine.length === 0) {
      formattedLines.push('')
      continue
    }

    // 减少缩进的情况
    if (trimmedLine.startsWith('}') || trimmedLine.startsWith(']') ||
        trimmedLine.startsWith(')') || trimmedLine === 'end' ||
        trimmedLine.startsWith('case ') || trimmedLine.startsWith('default:') ||
        trimmedLine.startsWith('elif ') || trimmedLine.startsWith('else:') ||
        trimmedLine.startsWith('except') || trimmedLine.startsWith('finally:') ||
        trimmedLine.startsWith('catch') || trimmedLine.startsWith('else {') ||
        trimmedLine.startsWith('else if')) {
      indentLevel = Math.max(0, indentLevel - 1)
    }

    // 添加缩进
    const indent = '    '.repeat(indentLevel)
    formattedLines.push(indent + trimmedLine)

    // 增加缩进的情况
    if (trimmedLine.endsWith('{') || trimmedLine.endsWith('[') ||
        trimmedLine.endsWith(':') || trimmedLine.endsWith('(') ||
        trimmedLine === 'begin' || trimmedLine.endsWith('then') ||
        trimmedLine.endsWith('do')) {
      indentLevel++
    }

    // 特殊情况：case/default 后面需要增加缩进
    if ((trimmedLine.startsWith('case ') || trimmedLine.startsWith('default:')) &&
        !trimmedLine.endsWith('{')) {
      indentLevel++
    }
  }

  return formattedLines.join('\n')
}

/**
 * 检测代码语言
 * 支持：C, C++, Java, JavaScript, TypeScript, Python, Go, Rust, C#, PHP, Swift, Kotlin, Ruby, SQL 等
 */
function detectCodeLanguage(code: string): string {
  // Rust 特征（优先检测，因为有独特语法）
  if (code.includes('fn ') && (code.includes('->') || code.includes('let mut') || code.includes('impl '))) {
    return 'rust'
  }

  // Go 特征
  if (code.includes('func ') && (code.includes('package ') || code.includes(':= ') || code.includes('go '))) {
    return 'go'
  }

  // Swift 特征
  if (code.includes('func ') && (code.includes('var ') || code.includes('let ')) && code.includes('->')) {
    return 'swift'
  }

  // Kotlin 特征
  if (code.includes('fun ') && (code.includes('val ') || code.includes('var '))) {
    return 'kotlin'
  }

  // C# 特征
  if (code.includes('using System') || code.includes('namespace ') && code.includes('class ') ||
      code.includes('public static void Main')) {
    return 'csharp'
  }

  // C/C++ 特征
  if (code.includes('#include') || code.includes('std::') || code.includes('nullptr') ||
      code.includes('int32_t') || code.includes('uint32_t') || code.includes('size_t') ||
      (code.includes('::') && (code.includes('void ') || code.includes('int ')))) {
    return 'cpp'
  }

  // Java 特征
  if (code.includes('public class') || code.includes('private void') ||
      code.includes('System.out') || code.includes('import java.') ||
      code.includes('@Override') || code.includes('public static void main')) {
    return 'java'
  }

  // TypeScript 特征（在 JavaScript 之前检测）
  if (code.includes(': string') || code.includes(': number') || code.includes(': boolean') ||
      code.includes('interface ') || code.includes(': void') || code.includes('<T>') ||
      code.includes('as ') && (code.includes('const ') || code.includes('let '))) {
    return 'typescript'
  }

  // JavaScript 特征
  if (code.includes('function ') || code.includes('const ') || code.includes('let ') ||
      code.includes('=>') || code.includes('console.log') || code.includes('require(') ||
      code.includes('module.exports') || code.includes('async ') || code.includes('await ')) {
    return 'javascript'
  }

  // Python 特征
  if (code.includes('def ') || code.includes('print(') || code.includes('self.') ||
      code.includes('__init__') || code.includes('elif ') || code.includes('import ') && code.includes(':')) {
    return 'python'
  }

  // Ruby 特征
  if (code.includes('def ') && code.includes('end') || code.includes('puts ') ||
      code.includes('require ') && code.includes("'") || code.includes('attr_')) {
    return 'ruby'
  }

  // PHP 特征
  if (code.includes('<?php') || code.includes('$_') || code.includes('echo ') ||
      (code.includes('$') && code.includes('function '))) {
    return 'php'
  }

  // SQL 特征
  if (code.toUpperCase().includes('SELECT ') || code.toUpperCase().includes('INSERT ') ||
      code.toUpperCase().includes('UPDATE ') || code.toUpperCase().includes('DELETE ') ||
      code.toUpperCase().includes('CREATE TABLE') || code.toUpperCase().includes('FROM ')) {
    return 'sql'
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

  // YAML 特征
  if (code.includes(': ') && !code.includes(';') && !code.includes('{') &&
      (code.includes('- ') || code.match(/^\w+:/m))) {
    return 'yaml'
  }

  // XML/HTML 特征
  if (code.includes('</') && code.includes('>')) {
    if (code.includes('<!DOCTYPE html') || code.includes('<html') || code.includes('<div') ||
        code.includes('<span') || code.includes('<p>')) {
      return 'html'
    }
    return 'xml'
  }

  // Shell/Bash 特征
  if (code.startsWith('#!/') || code.includes('echo ') || code.includes('$ ') ||
      code.includes('export ') || code.includes('chmod ') || code.includes('sudo ')) {
    return 'bash'
  }

  // Makefile 特征
  if (code.includes(':=') && code.includes('\t') || code.includes('.PHONY')) {
    return 'makefile'
  }

  // Dockerfile 特征
  if (code.includes('FROM ') && (code.includes('RUN ') || code.includes('CMD ') || code.includes('COPY '))) {
    return 'dockerfile'
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
  private context: common.UIAbilityContext | undefined = undefined

  async aboutToAppear(): Promise<void> {
    // 获取上下文
    try {
      this.context = getContext(this) as common.UIAbilityContext
    } catch (e) {
      logger.error(`${LOG_TAG.NEWS_LIST}获取上下文失败`)
    }

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

  /**
   * 渲染包含链接的文本
   */
  @Builder
  TextWithLinksBuilder(text: string) {
    if (containsLink(text)) {
      // 包含链接，需要拆分渲染
      Text() {
        ForEach(parseTextWithLinks(`        ${text}`), (segment: TextSegment, idx: number) => {
          if (segment.type === 'link') {
            Span(segment.content)
              .fontColor($r('app.color.brand'))
              .decoration({ type: TextDecorationType.Underline, color: $r('app.color.brand') })
              .onClick(() => {
                if (this.context && segment.url) {
                  openExternalLink(segment.url, this.context)
                }
              })
          } else {
            Span(segment.content)
          }
        }, (segment: TextSegment, idx: number) => `${segment.type}_${idx}_${segment.content.substring(0, 10)}`)
      }
      .fontSize(this.baseFontSize + (this.deviceType === DEVICE_TYPES.PHONE ? 0 : 6))
      .width('90%')
      .alignSelf(ItemAlign.Center)
    } else {
      // 不包含链接，直接渲染
      Text(`        ${text}`)
        .fontSize(this.baseFontSize + (this.deviceType === DEVICE_TYPES.PHONE ? 0 : 6))
        .width('90%')
        .alignSelf(ItemAlign.Center)
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
            this.TextWithLinksBuilder(item.value)
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