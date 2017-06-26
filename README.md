# Replayer

[![Build Status](https://travis-ci.org/zhangqifan/Replayer.svg?branch=master)](https://travis-ci.org/zhangqifan/Replayer)

Replayer 是一款基于 **[AVFoundation](https://developer.apple.com/documentation/avfoundation)** 框架编写的视频播放器，支持 iOS 7 及其以上版本的系统。采用 MVC 的设计模式，分离了对播放器的操作和操作引起视图或布局的变化，并提供了对视频控制视图的自定义以及扩展功能的支持。

当前版本：***0.1.0***

## 支持的功能

> 注意：0.1.0 版本只支持基础的部分功能，**标注 * 的功能条目目前暂不支持**，计划后续版本更新。

* 支持横竖屏切换，支持入口单一横屏模式；
* *支持视频清晰度调节；
* 支持网络状态监测，支持在非 WiFi 环境下播放视频前的播放拦截，以及播放过程中的网络状况切换提示；
* 支持断点播放；
* 支持加载失败 / 加载超时 / 缓冲中断的错误处理；
* 在网络环境差的状况下优化播放体验；
* 支持播放结束之后的操作（支持添加一些业务逻辑等）；
* 支持亮度、音量调整；
* 支持全屏播放进度更改、进度条进度拖动 / 点选时间；
* 支持播放本地视频
* *支持 AirPlay
* *兼容 iOS 10+ 的新特性

## 工具原料

* **Xcode 8** 及其以上版本
* **iOS 7** 及其以上版本

## 组件依赖

> *MMMaterialDesignSpinner* 和 *Toast* 为非必要组件，替代品会在之后的版本中集成入 Replayer 中。

* [Masonry](https://github.com/SnapKit/Masonry)
* [MMMaterialDesignSpinner](https://github.com/misterwell/MMMaterialDesignSpinner)
* [Toast](https://github.com/scalessec/Toast)

## 使用说明

## 值得去做、提上日程的事

* [ ] 添加 Travis.CI 支持


* [ ] 在 CocoaPods 中注册库


* [ ] 编写一个 Demo 示例


* [ ] 优化、尽可能地减少 bugs & crash

## License

Copyright 2017 Qifan Zhang

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
