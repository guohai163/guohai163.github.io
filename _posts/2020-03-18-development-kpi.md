---
layout: post
title:  "开发岗位绩效工资怎么评定"
date:   2020-03-18 10:02:02
categories: [develop, life]
tags: [develop, kpi]
image: /doc-pic/2020-03/what-are-key-performance-indicators-kpis.png
---
今天我们来探讨下开发岗位的绩效实现方案。绩效就是对于每个人工作量的一个评定，并进行相应的奖惩。最先应用的是传统的流水线工作：直接计件就可以，随着中国进入了互联网时代。老板们为了避免程序员们上班摸鱼也开始考虑能否给开发岗位引入绩效方案。最初级的时候真的就是一个计件的工作，按写多少行代码来进行统计【据说目前在华为内部还有团队在执行这个方案】。但道高一尺魔高一丈，程序员们就开始就小想法了，能不写一行的就不写在一行，甚至在代码中出现无引用的函数👨🏽‍💻。这种方法肯定是不可取的，接下来看看我们团队的心路历程:

## 初期人工打分
我们团队最开始引入绩效考核时还是全人工给每个迭代/版本进行打总分的方式【评定方法主要是看程序的处理复杂度，人工评定】，然后参与这个迭代的人员平分得分。吃大锅饭的方法持续了几个月就进行不下去了，随着绩效对工资影响占比变高，开发开始重视绩效，就会反馈太不公平，同一个项目里的人干多干少拿一样的得分。开会探讨方案改革，改为对迭代内每个故事进行单独打分，同一个故事每一个岗位最多一个人领取，冲突消失。但打分时间变长，一个月的工作量要消耗4个打分人员3天左右的时间【更多的是争吵某一个任务应该给多少分，评分人员也想给自己的项目组争取更多的绩效点数】。

一开始是使用excel进行计分，人工核算。人总有失误的时候，会出现记分错误而且占用的时间也不少。团队内都是开发人员，最喜欢让工具来完成重复的工作🧠，没有现成的程序，就考虑自己实现吧。成品很强大，甚至可以当产品来出售，评委打分的时候直接用手机打开个页面，把自己想打的分添进去。然后自动计算，产生报表👍🏼。我的天啊👹这套程序就开始了1.0版本，并不停的改造。从项目管理+版本管理+人员管理+要记分体系+手机版本。前前后后也占用了一个开发+一个测试快一个月的时间，总算自动化了🥶。

但随着打分的时间变长，人总会有惰性，一开始的想法是4个人同时打分，取平均分。争吵的多了，大家也觉得打分太浪费自己的时间，有这时间不如多写几行代码，多学点新知识。进行到最后只要有一个人进行打分，其他人就会跟分。那第一个打分的人肯定是更多的参与了这个项目的人，人情分开始占主要矛头。以失败告终。🤬【为此我们的团队甚至使用过所有人思考打分把分数反扣在桌子上，然后后同时亮出分数。这个过程在此就不细聊了】


## 把打分客观化
之前的打分还是不够客观，失败不是最终目标，我们还要再次思考。我们得改变计算方法，想一些客观的数据出来能够代表大家的工作量的方法。我们团队想到了测试用例的这个点上🗯，对于测试用例我们按重要性划分为3个等级，只有前2个等级做为分数的主要计算项。之前的绩效计算系统又面临新的改版。目前在正常的版本迭代上来看这可能是相对准确的工作量计算方法了，当然付出也是巨大的。因为我们不是研发团队，是运营开发。同时我们的绩效系统还要考虑到版本以外的紧急任务常规任务，所谓的紧急任务就是一个线上问题可能是性能问题，或是一个网络故障需要开发拿出很多的时间分析问题并最终解决问题，但紧急任务并没有对应的测试用例需要主观的给一个评定分，真的是越来越复杂的计算公式。

![dev-kpi](/doc-pic/2020-03/dev-kpi.png)


## 痛定思痛
目前这套绩效机制已经运行了几年了，可能我得承认目前的方案中能`代表工作量`的比较好的方法。但工作量是否能代表对人工作能力和付出的考核确实是不客观的。开发肯定不是接收到需求就简单的开始重复工作，是一个需要需要创作的工作。而且各岗位之间也更多的应该是合作关系而不是竞争关系（比如QA找到多少个BUG给开发扣多少分，给测试加多少分的现象就是一个竞争关系）。目前的绩效方案一开始可能还算正常，因为对个人的收入影响不大，但一旦调整绩效的占比后已经变了味道，思考2019年底会会时我们评定出了2019年度绩效拿A最多的人，大家看到结果后会承认他是付出最多的，或者甚至说一定是工作量最饱满的人吗？

目前的绩效方案会产生的一个致命问题是做重复的工作拿高绩效分的可能性越大，有创造性的需要通过分析来解决问题并创造或改造现有程序的越不容易拿高绩效。目前的现象就是开发都愿意参与新项目的开发，只要了解眼前的需求并快速的开发就可以很容易的拿到A。而给公司源源不断带来收入的项目因为进入了维护阶段，每次修改或者解决线上问题都要翻看大量的代码思考如何重构或解决问题，但却很容易拿到C的现象。

另一方面绩效方案实施了几年后，我们也同时在进行了末位淘汰机制，淘汰了几轮后，目前处于末位可能已经不是不努力/能力不行了。也许只是分配的工作在绩效考核上不占优势了。因我们的绩效方案是完全公开透明的，最近一次的绩效评定为C的人，当事人没有什么意见表示愿意接受，但其他人会和我反馈“海哥，咱们这个月得C的L同学上个月工作可是很努力的，完成了很多工作。不能因为相对应的测试用例少就不肯定人家的工作吧。”

## 重新考虑
还是先肯定目前TC确实能在一定程度上代表未来要进行的工作量，可以用来预估未来工作量的完成进度。但不能代表开发团队个人的工作绩效，而且目前围绕绩效的公平性（因为与钱挂钩，员工关心的程度越高）做的各种工具成本已经有点高了。而工作量这个`即使没有绩效体系也还是需要大家按时完成指定工作量`的，因为还有需求方以及整个团队领导都在盯着项目的进度看。

也看了很多公司的OKR部分，大多只是做过团队的推动力，老板先进行公开自己的OKR。之后团队和个人针对老板的OKR来计划自己的OKR。但只是做为公司的一个发展方向并不做为考核指标。

是否可以废除目前的绩效体系，默认所有人都是正常绩效评定。当有人或项目组完成某个重要商业目标时,或者主动发现并优化解决了一些事情，再或者能够积极快速响应并解决线上问题给予项目组或个人优秀的评定。同样某个项目组或个人在当月犯了比较严重的错误【可能是代码质量得分】让某表商业目标没有完成或者失败【可能是运维质量，产生了线上问题】给予差的评定。

### 再再次重新考虑

经过之前的考虑，但是目前公司的绩效目前不适宜做的大的改动。应该首先让商业价值更高的所有偏重。目前团队中商业价值或重要性最高的应该是目前占公司主要收入的问道相关以及新业务方向。其中新业务的工作量是目前在绩效上已经照顾到的部分，考虑增加对于迭代贡献度的一个奖励体系，而线上业务的维护是目前绩效体系未照顾到的部分，应该在绩效上有所偏向。

3. 线上问题在<font color="#FF0000">未产生严重后果前</font>处理完做相应的加分
    * 工作时间内的线上问题解决一次性给予5分
    * 工作时间外的线上问题解决一次性给予15分
    * 个人或与需求放系统部协商提出有修改价值的优化并在本月内实施优化看到成果的，给予<font color="#FF0000">50分奖励</font>
1. 迭代版本贡献度奖励
    * PO能够完全清晰的讲解需求应给予10%加分，由开发和测试来判定
    * 测试可以在迭代开始前写完T1T2级别的用例应给予10%加分，由开发和PO来进行判定
    * 开发在迭代内可以分拨进行送测应给予10%加分，由测试和PO进行判定
2. 迭代版本内必须完成的
    * 迭代开始前必须录入所有故事的规模，规模为T1+T2的用例数
    * 所有成员在完成手中工作后必须即时挪动故事条
    * PO在有测试完的故事条时必须及时进行验收工作
    * 以上工作由SM协助完成，完成情况不好的SM有权利在月底做出扣分处理。

4. 项目进度的展示
    * 项目进度的最好展示方法肯定还是燃尽图，下图我们可以看下一个是使用故事个数为单位，一个是使用项目规模为单位的图表。肯定是以规模为单位的更准确
    * 故事的规模我建议使用功能点为单位

![burn down chart](/doc-pic/2020-03/burn-down-chart.png)