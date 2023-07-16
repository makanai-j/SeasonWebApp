using System;
using System.Diagnostics;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using OpenAI_API;

namespace _0H05026_蒔苗純平_uiux01
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public static Uri? imageSpring;
        public static Uri? imageSummer;
        public static Uri? imageAutumn;
        public static Uri? imageWinter;
        public static Uri? imageBack;

        public static BitmapImage bi;

        class KigosObj
        {
            public string[] spring { get; set; }
            public string[] summer { get; set; }
            public string[] autumn { get; set; }
            public string[] winter { get; set; }
            public string springcr { get; set; }
            public string summercr { get; set; }
            public string autumncr { get; set; }
            public string wintercr { get; set; }
        }


        KigosObj? kigos;
        int kigosTextNum;

        readonly DispatcherTimer timer = new DispatcherTimer();
        public MainWindow()
        {
            InitializeComponent();

            monthTextBox.Focus();

            imageSpring = new Uri("images\\efSpring.mp4", UriKind.Relative);
            imageSummer = new Uri("images\\efSummer.mp4", UriKind.Relative);
            imageAutumn = new Uri("images\\efAutumn.mp4", UriKind.Relative);
            imageWinter = new Uri("images\\efWinter.mp4", UriKind.Relative);
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            const string pythonPass = "getKigo.py";

            var result = string.Empty;

            var process = new Process
            {
                StartInfo = new ProcessStartInfo("python.exe")
                {
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    Arguments = pythonPass
                }
            };
            // python.exeの起動
            process.Start();

            // python.exeの実行結果を読み込み
            var reader = process.StandardOutput;
            result = reader.ReadLine();

            // python.exeのプロセスの終了待ち
            process.WaitForExit();

            //JsonSerializerはすべてダブルクオーテーションでないとExceptionを吐く
            //ok  -> { "spring":"落花" }
            //bad -> { "spring":'落花' }や{ 'spring':"落花" }
            kigos = JsonSerializer.Deserialize<KigosObj>(result);

            kigosTextNum = 0; //本来の数
            for (int j = 0; j < 2; j++){
                for (int i = 0; 30 * (i + 1) + 30 <= kigosCanvas.Height; i++, kigosTextNum++)
                {
                    setLabels(kigosTextNum, i, j);
                }
            }

            timer.Interval = new TimeSpan(0, 0, 0, 0, 50);    //インターバルを50ミリ秒に設定
            timer.Tick += new EventHandler(kigosTimer);
        }

        public int countK = 0;
        private void kigosTimer(object sender, EventArgs e)
        {
            if (countK < kigosTextNum)
            {
                var label = new System.Windows.Controls.Label();
                label = (System.Windows.Controls.Label)this.kigosCanvas.FindName("tbox" + countK);
                label.Visibility = Visibility.Visible;
                countK++;
            }
            else
            {
                countK = 0;
                timer.Stop();
            }
        }

        public void setLabels(int k, int i, int j)
        {
            int mTop = 28 * (i + 1);
            int mleft = (int)(kigosCanvas.Width / 2) * j + 20;

            var label = new System.Windows.Controls.Label();
            label.Name = "tbox" + (k) ; //Name
            kigosCanvas.Children.Add(label);
            kigosCanvas.RegisterName(label.Name, label);

            label = (System.Windows.Controls.Label)this.kigosCanvas.FindName("tbox"+ (k));
            label.Foreground = new SolidColorBrush(Color.FromArgb(0xFF, 0xCC, 0xCC, 0xCC));
            label.FontSize = 15;
            label.Height= 50;
            label.Margin = new Thickness( mleft, mTop, 0, 0);
            label.FontFamily = new FontFamily("Sans Serif Collection");
            label.Visibility = Visibility.Hidden;
            label.MouseDown += new MouseButtonEventHandler(getHaikuByChatGpt);
            label.MouseEnter+= new MouseEventHandler(chatGptLabel_EnterEvent);
            label.MouseLeave += new MouseEventHandler(chatGptLabel_LeaveEvent);
        }

        /**********************
         * textboxへ入力したときの判定
         * 1から12までの数字のみ入力可能
         **********************/
        int monthTextInt = 0;
        private void monthText_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            var textBox = (TextBox)sender;
            textBox.ContextMenu = null;
            string monthText = textBox.Text;
            var inputmonthText = e.Text;
            int monthInputTextInt;

            bool neko = new System.Text.RegularExpressions.Regex("[0-9]").IsMatch(inputmonthText);
            int.TryParse(monthText, out monthTextInt);
            int.TryParse(inputmonthText, out monthInputTextInt);

            if (!neko || (monthInputTextInt == 0 && monthTextInt == 0) || monthTextInt >= 2 || (monthTextInt == 1 && monthInputTextInt >= 3))
            {
                e.Handled = true;//無効
            }
        }
        //スペースキーが押されたときは、それを無効にする
        private void mouthTextBox_PreviewKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Space) e.Handled = true;
        }

        private void batsuImage_mouseEnter(object sender, System.EventArgs e)
        {
            batsuImage.Background = new SolidColorBrush(Color.FromArgb(0x66, 0xBB, 0xBB, 0xBB));
        }
        private void batsuImage_mouseLeave(object sender, System.EventArgs e)
        {
            batsuImage.Background = new SolidColorBrush(Color.FromArgb(0x00, 0x00, 0x00, 0x00));
        }
        private void rootGrid_mouseDown(object sender, MouseEventArgs e)
        {
            //Keyboard.ClearFocus();
        }

        private void batsuImage_mouseDown(object sender, MouseEventArgs e)
        {
            monthTextBox.Clear();

            monthTextBox.Focus();
        }

        private void monthTextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            textBoxEvent();
        }
        private void monthTextBox_MouseDown(object sender, MouseButtonEventArgs e)
        {
            textBoxEvent();
        }

        public void textBoxEvent()
        {
            if (monthTextBox.Text.Length > 0)
            {
                monthTextBoxHint.Visibility = Visibility.Hidden;
                batsuImage.Visibility = Visibility.Visible;
                monthLabel.Visibility = Visibility.Hidden;
            }
            else
            {
                monthTextBoxHint.Visibility = Visibility.Visible;
                batsuImage.Visibility = Visibility.Hidden;
                monthLabel.Visibility = Visibility.Visible;
            }
        }

        private void OnKeyDownHandler(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
            {
                Keyboard.ClearFocus();
                batsuImage.Visibility = Visibility.Hidden;
                monthLabel.Visibility = Visibility.Visible;

                int month;

                if (int.TryParse(monthTextBox.Text, out month))
                {
                    setGif(month);
                }            
            }
        }

        int[] randA;
        private void setGif(int month)
        {
            kigosHint.Visibility = Visibility.Hidden;
            kigosHint.Content = "chatGPTに質問中...";

            switch (month)
            {
                //spring
                case 3:
                case 4:
                case 5:
                    playMedia(imageSpring);
                    setKigos(kigos.spring);
                    season.Content = "春";
                    crText.Content = kigos.springcr;
                    break;
                //summer
                case 6:
                case 7:
                case 8:
                    playMedia(imageSummer);
                    setKigos(kigos.summer);
                    season.Content = "夏";
                    crText.Content = kigos.summercr;
                    break;
                //autumn
                case 9:
                case 10:
                case 11:
                    playMedia(imageAutumn);
                    setKigos(kigos.autumn);
                    season.Content = "秋";
                    crText.Content = kigos.autumncr;
                    break;
                //winter
                case 12:
                case 1:
                case 2:
                    playMedia(imageWinter);
                    setKigos(kigos.winter);
                    season.Content = "冬";
                    crText.Content = kigos.wintercr;
                    break;
            }
        }

        public void setKigos(string[] kigos)
        {
            //表示中の可能性もあるため一度riset
            timer.Stop();
            countK = 0;
            kigosHint.Visibility = Visibility.Hidden;
            chatgptCanvas.Visibility = Visibility.Hidden;
            ByChatGPT.Visibility = Visibility.Hidden;
            kigosCanvas.Visibility = Visibility.Visible;

            Random rand = new Random();
            randA = new int[kigos.Length];

            for (int i = 0; i < kigosTextNum; i++)
            {
                int randNum = rand.Next(0, kigos.Length);
                if (Array.IndexOf(randA, randNum) == -1)
                {
                    var label = new System.Windows.Controls.Label();
                    label = (System.Windows.Controls.Label)this.kigosCanvas.FindName("tbox" + i);
                    label.Content = kigos[randNum];
                    randA[i] = randNum;

                    label.Visibility = Visibility.Hidden;
                }
                else
                {
                    --i;
                }
            }
            timer.Start();
        }
        private void playMedia(Uri img)
        {
            myMediaElement.Source = null;
            myMediaElement.Source = img;
            myMediaElement.Play();
        }

        //chatGPT
        //参考URL:https://chigusa-web.com/blog/csharp-chatgpt-api/
        private async Task chatGptAsync(string pp)
        {
            var api = new OpenAI_API.OpenAIAPI("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");
            var chat = api.Chat.CreateConversation();

            string ss = (string)season.Content;

            // ChatGPTに質問
            chat.AppendUserInput(ss+"の季語である「"+ pp +"」を使用した"+ss+"の俳句を1つ考えて、各句の間には改行を入れてください。");

            // ChatGPTの回答
            string response = await chat.GetResponseFromChatbotAsync();

            if (response.Length > 0)
            {
                kigosHint.Visibility = Visibility.Hidden;
                chatgptCanvas.Visibility = Visibility.Visible;
                ByChatGPT.Visibility = Visibility.Visible;
                string[] res = response.Split('　');
                if(res.Length < 3) res = response.Split(' ');
                if(res.Length < 3) res = response.Split("\n");
                chatgptLabel1.Content = res[0]; 
                chatgptLabel2.Content = res[1]; 
                chatgptLabel3.Content = res[2]; 
            }
        }
        private void getHaikuByChatGpt(object sender, EventArgs e)
        {
            kigosCanvas.Visibility = Visibility.Hidden;
            kigosHint.Visibility = Visibility.Visible;

            Label lb = new Label();
            lb = (Label)sender;
            string pp = (string)lb.Content;
            pp = pp.Split("(")[0];
            chatGptAsync(pp);
        }
        private void chatGptLabel_EnterEvent(object sender, System.EventArgs e)
        {
            Label lb = new Label();
            lb = (Label)sender;

            lb.Foreground = Brushes.White;
            lb.FontWeight = FontWeights.Bold;
        }
        private void chatGptLabel_LeaveEvent(object sender, System.EventArgs e)
        {

            Label lb = new Label();
            lb = (Label)sender;
            
            lb.Foreground = new SolidColorBrush(Color.FromArgb(0xFF, 0xCC, 0xCC, 0xCC));
            lb.FontWeight = FontWeights.Light;
        }

    }
}
