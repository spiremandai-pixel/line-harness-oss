-- Migration 013: rich_menu_postback_responses 再シード (UTF-8 BOMなし・絵文字直書き)
DELETE FROM rich_menu_postback_responses;

INSERT OR REPLACE INTO rich_menu_postback_responses (payload, name, body_json, updated_at) VALUES

('store_select_carousel', '①予約タップ後・店舗選択カルーセル',
'{"messages":[{"type":"template","altText":"ご希望の店舗をお選びください","template":{"type":"carousel","imageAspectRatio":"rectangle","imageSize":"cover","columns":[{"thumbnailImageUrl":"https://placehold.co/1024x1024/1E3A8A/FFFFFF.jpg","title":"経堂コルティ店","text":"東京都世田谷区／小田急線「経堂駅」直結","actions":[{"type":"uri","label":"予約する","uri":"https://denba-4cshd.com/l_inquiry/?store=2&menu=1&ad_code=6"}]},{"thumbnailImageUrl":"https://placehold.co/1024x1024/1E4A8A/FFFFFF.jpg","title":"イオンモール浦和美園店","text":"埼玉県さいたま市緑区／浦和美園駅 徒歩3分","actions":[{"type":"uri","label":"予約する","uri":"https://denba-4cshd.com/l_inquiry/?store=1&menu=1&ad_code=6"}]}]}}]}',
datetime('now','+9 hours')),

('denba_intro', '②DENBAとは・画像+テキスト',
'{"messages":[{"type":"image","originalContentUrl":"https://placehold.co/1024x1024/0E2A7A/FFFFFF.jpg","previewImageUrl":"https://placehold.co/1024x1024/0E2A7A/FFFFFF.jpg"},{"type":"text","text":"【DENBAラウンジとは？】\n\nDENBA(デンバ)は、もともと食品の鮮度を保つために生まれた技術です。水分を分子レベルでやさしく振動させることで、本来の流れを取り戻すサポートをします。\n\nその技術を、人にも――。\n横になるだけで、肩や腰の重さがふっと軽くなる。眠りが深くなった、朝の目覚めが変わった、というお声が続々と届いています。\n\n🛏 富士そば／アパホテル／医療・介護施設にも導入実績あり\n🎓 東京大学との共同研究による空間電位技術\n⏱ 体験時間は15〜20分。料金は無料です。\n\n「気になっていたけど、なかなか機会がなかった」\nそんな方こそ、ぜひ一度体感してみてください。\n\nご予約はメニューの「予約する」ボタンから🔻"}]}',
datetime('now','+9 hours')),

('store_list_carousel', '③店舗一覧・2店舗カルーセル',
'{"messages":[{"type":"template","altText":"DENBAラウンジ 店舗一覧","template":{"type":"carousel","imageAspectRatio":"rectangle","imageSize":"cover","columns":[{"thumbnailImageUrl":"https://placehold.co/1024x1024/1E3A8A/FFFFFF.jpg","title":"経堂コルティ店","text":"経堂駅直結／10:00〜20:00","actions":[{"type":"uri","label":"予約する","uri":"https://denba-4cshd.com/l_inquiry/?store=2&menu=1&ad_code=6"}]},{"thumbnailImageUrl":"https://placehold.co/1024x1024/1E4A8A/FFFFFF.jpg","title":"イオンモール浦和美園店","text":"浦和美園駅 徒歩3分／10:00〜21:00","actions":[{"type":"uri","label":"予約する","uri":"https://denba-4cshd.com/l_inquiry/?store=1&menu=1&ad_code=6"}]}]}}]}',
datetime('now','+9 hours')),

('faq_menu', '④FAQ入口・4択クイックリプライ',
'{"messages":[{"type":"text","text":"よくあるご質問はこちらから📩\n\nお知りになりたい項目をお選びください👇","quickReply":{"items":[{"type":"action","action":{"type":"postback","label":"メアド確認","data":"payload=faq_email_support","displayText":"メアド確認"}},{"type":"action","action":{"type":"postback","label":"予約変更・キャンセル","data":"payload=faq_change_cancel","displayText":"予約変更・キャンセル"}},{"type":"action","action":{"type":"postback","label":"体験内容・所要時間","data":"payload=faq_experience","displayText":"体験内容・所要時間"}},{"type":"action","action":{"type":"postback","label":"はじめての方へ","data":"payload=faq_first_visit","displayText":"はじめての方へ"}}]}}]}',
datetime('now','+9 hours')),

('faq_email_support', 'FAQ-1入口・2択分岐',
'{"messages":[{"type":"text","text":"予約フォームでメールアドレスの入力に困った方へ📩\n\n以下のどちらに当てはまりますか？","quickReply":{"items":[{"type":"action","action":{"type":"postback","label":"1️⃣ 自分のメアド確認","data":"payload=faq_email_self","displayText":"自分のメアドを確認したい"}},{"type":"action","action":{"type":"postback","label":"2️⃣ 家族メアドで予約","data":"payload=faq_email_family","displayText":"家族メアドで予約したい"}}]}}]}',
datetime('now','+9 hours')),

('faq_email_self', 'FAQ-1[1]メアド確認手順',
'{"messages":[{"type":"text","text":"ご自身のメールアドレスを確認しましょう📱\n\nまず、メアドの「@(アットマーク)から後ろの文字」を思い出せるか確認してみてください。\n\n▼ @gmail.com の方\n　ホーム画面の「Gmail」アプリを開く\n　→ 右上のアイコン → ご自身のアドレスが表示されます\n\n▼ @icloud.com / @me.com の方(iPhone)\n　「設定」アプリ → 一番上のお名前をタップ\n　→ Apple IDの下にメールアドレスが表示されます\n\n▼ @docomo.ne.jp / @ezweb.ne.jp / @softbank.ne.jp の方\n　各キャリアのメールアプリを開く\n　→ 設定 or アカウント情報からアドレス確認\n\n▼ どれにも当てはまらない / 分からない方\n　お気軽にこのトークでメッセージください💬\n　スタッフがお調べいたします(営業時間内:10:00〜20:00)"}]}',
datetime('now','+9 hours')),

('faq_email_family', 'FAQ-1[2]家族メアド案内',
'{"messages":[{"type":"text","text":"ご家族のメールアドレスでも予約可能です✉️\n\n▼ ご予約時のお願い\n予約フォームの「お名前」欄には【体験される方ご本人のお名前】をご記入ください。\n　※ご家族のお名前ではありません\n\n▼ 確認メールについて\nご予約完了メールはご家族宛に届きます。当日の日時をご家族と共有いただけますとスムーズです。\n\n▼ それでもご不明な点があれば\nこのトークでメッセージください💬\nスタッフがサポートいたします。"}]}',
datetime('now','+9 hours')),

('faq_change_cancel', 'FAQ-2予約変更・キャンセル',
'{"messages":[{"type":"text","text":"ご予約の変更・キャンセルは、予約完了時にお送りしたメール記載のリンクから行えます。\n\n▼ 変更したい場合\n予約完了メールの「予約内容を確認・変更」ボタン\n　→ 日時を選び直して確定\n\n▼ キャンセルしたい場合\n同メールの「キャンセル」ボタン\n　→ 確認画面で「キャンセル確定」\n\nメールが見当たらない場合は、お手数ですがこのトーク画面でお名前・現在の予約日時をお送りください🙇"}]}',
datetime('now','+9 hours')),

('faq_experience', 'FAQ-3体験内容・所要時間',
'{"messages":[{"type":"text","text":"▼ 体験内容\n専用シートに横になっていただくだけ。着替えは不要、お洋服のままで大丈夫です。\n\n▼ 所要時間\n・受付・ヒアリング:約3分\n・体験:15分\n・ご感想ヒアリング:約5分\n合計で 20〜25分 ほどお時間をいただきます。\n\n▼ 料金\n完全無料です。販売目的の強引な勧誘は一切ございませんので、安心してお越しください😊"}]}',
datetime('now','+9 hours')),

('faq_first_visit', 'FAQ-4はじめての方へ',
'{"messages":[{"type":"text","text":"▼ 体験は完全無料です\n料金は一切かかりません。お気軽にお越しください。\n\n▼ 強引な勧誘はいたしません\n「商品を買わないと帰れない…」ということは絶対にありません。体験のみで気軽にお帰りいただけます。気に入っていただいた方にだけ、ご自宅用の商品をご案内しています。\n\n▼ ご家族・ご友人とのご来店も歓迎です\nご一緒に体験されたい方は、それぞれのお名前で予約フォームからお申込みください。\n\n▼ 2回目以降のご来店も大歓迎です\n体感は回数を重ねるほど深まる方もいらっしゃいます。\n\n▼ お洋服のままで体験できます\n着替えは不要です。靴を脱いで横になっていただくだけで大丈夫。お仕事帰り・お買い物のついでにもどうぞ🛍\n\nご不明な点があれば、このトークでお気軽にメッセージください💬"}]}',
datetime('now','+9 hours')),

('off_hours_auto_reply', '営業時間外自動応答',
'{"messages":[{"type":"text","text":"お問い合わせありがとうございます🌙\n\nただいま営業時間外(営業時間:10:00〜20:00)のため、スタッフからのご返信は翌営業日となります。\n\nお急ぎの場合は、下記のリッチメニューからご予約やよくあるご質問もご確認いただけます🙇\n\nご返信まで今しばらくお待ちください。"}]}',
datetime('now','+9 hours'));
