//
//  ViewController.m
//  Socket
//
//  Created by 陈绪混 on 2016/10/31.
//  Copyright © 2016年 Chenxuhun. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <NSStreamDelegate,UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>
{
    NSInputStream  *_inputStream; //对应输入流
    NSOutputStream *_outputStream; //对应输出流
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *chatMsgs; //聊天消息数组

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}

#pragma mark 链接服务器
- (IBAction)connectToHost:(id)sender
{
    // 建立连接 服务器的IP地址
    NSString *host = @"112.74.98.189";
    // 端口地址
    int port = 50000;
    
    // 定义C语言输入输出流
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    
    // 把C语言的输入输出流转化成OC对象
    _inputStream = (__bridge NSInputStream *)(readStream);
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    
    // 设置代理
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    // 把输入输入流添加到主运行循环
    // 不添加主运行循环 代理有可能不工作
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    // 打开输入输出流
    [_inputStream open];
    [_outputStream open];
}

#pragma mark 监听连接代理
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    //  打印所在线程
    NSLog(@"%@",[NSThread currentThread]);
    //    NSStreamEventOpenCompleted = 1UL << 0,//输入输出流打开完成
    //    NSStreamEventHasBytesAvailable = 1UL << 1,//有字节可读
    //    NSStreamEventHasSpaceAvailable = 1UL << 2,//可以发放字节
    //    NSStreamEventErrorOccurred = 1UL << 3,// 连接出现错误
    //    NSStreamEventEndEncountered = 1UL << 4// 连接结束
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
            NSLog(@"输入输出流打开完成");
            
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"有字节可读");
            
            [self readData];
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"可以发送字节");
            
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@" 连接出现错误");
            
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"连接结束");
            
            // 关闭输入输出流
            [_inputStream close];
            [_outputStream close];
            
            // 从主运行循环移除
            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            break;
        default:
            break;
    }
}

// ------- 华丽的分割线 以上成功后才会有以下 ---------

#pragma mark 登录服务器 这里不需要理会 如果连接成功了再做别的逻辑
- (IBAction)loginBtnClick:(id)sender
{
    // 登录
    // 发送用户名和密码
    // 在这里做的时候，只发用户名，密码就不用发送
    
    // 如果要登录，发送的数据格式为 "iam:zhangsan";
    // 如果要发送聊天消息，数据格式为 "msg:did you have dinner";
    
    //登录的指令
    NSString *loginStr = @"iam:zhangsan";
    
    //把Str转成NSData
    NSData *data = [loginStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [_outputStream write:data.bytes maxLength:data.length];
}

#pragma mark 读了服务器返回的数据
- (void)readData
{
    // 建立一个缓冲区 可以放1024个字节
    uint8_t buf[1024];
    
    // 返回实际装的字节数
    NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
    
    // 把字节数组转化成字符串
    NSData *data = [NSData dataWithBytes:buf length:len];
    
    // 从服务器接收到的数据
    NSString *recStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@",recStr);
    
    [self reloadDataWithText:recStr];
}

#pragma mark 发送数据
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *text = textField.text;
    
    NSLog(@"%@",text);
    // 聊天信息
    NSString *msgStr = [NSString stringWithFormat:@"msg:%@",text];
    
    //把Str转成NSData
    NSData *data = [msgStr dataUsingEncoding:NSUTF8StringEncoding];
    
    // 刷新表格
    [self reloadDataWithText:msgStr];
    
    // 这里可以传输字典
    NSDictionary *dic = [NSDictionary dictionary];
    NSData *pData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    
    // 发送数据
    [_outputStream write:pData.bytes maxLength:data.length];
    
    // 发送完数据，清空textField
    textField.text = nil;
    
    return YES;
}

#pragma mark 实现数据的显示，并且每发送一次消息都会滚动到对应的位置
- (void)reloadDataWithText:(NSString *)text
{
    [self.chatMsgs addObject:text];
    
    [self.tableView reloadData];
    
    // 数据多，应该往上滚动
    NSIndexPath *lastPath = [NSIndexPath indexPathForRow:self.chatMsgs.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark 表格的数据源
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.chatMsgs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    cell.textLabel.text = self.chatMsgs[indexPath.row];
    
    return cell;
}

- (NSMutableArray *)chatMsgs
{
    if (!_chatMsgs)
    {
        _chatMsgs = [NSMutableArray array];
    }
    return _chatMsgs;
}


@end
