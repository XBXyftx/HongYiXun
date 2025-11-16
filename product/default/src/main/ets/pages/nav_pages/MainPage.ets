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

const MainPage_TAG = 'MainPage: '

@Preview
@ComponentV2
export struct MainPage {







  build() {
    NavDestination() {

    }
    .linearGradient({
      angle: 20,
      colors: [
        [$r('app.color.index_page_background_1'), 0],
        [$r('app.color.index_page_background_2'), 0.4],
        [$r('app.color.index_page_background_3'), 0.7],
        [$r('app.color.index_page_background_4'), 1]
      ]
    })
    .width('100%')
    .height('100%')
  }
}
