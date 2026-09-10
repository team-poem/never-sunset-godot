extends RefCounted

static func _page(title: String, body: String, choices: Array = []) -> Dictionary:
	return {"title":title, "body":body, "choices":choices if not choices.is_empty() else [{"text":"계속", "action":""}]}

static func _choice(text: String, action: String) -> Dictionary:
	return {"text":text, "action":action}

static func objective(phase: String, memories: int) -> String:
	match phase:
		"home":
			if memories >= 3: return "욕실에서 손을 씻고 차를 마시자."
			return "현관문 왼쪽 문틀 · 가족사진 · 식탁의 컵 (%d/3)" % memories
		"return": return "손을 씻었다. 식탁으로 돌아가 컵을 들어 보자."
		"dusk": return "거실이 아직 밝다. 베란다 커튼을 확인하자."
		"drain": return "주방에서 물 빠지는 소리가 난다. 싱크대를 확인하자."
		"signal": return "현관에서 공동현관 호출이 울린다. 월패드를 확인하자."
		"pulse": return "욕실에서 진동이 느껴진다. 벽면 타일을 확인하자."
		"escape": return "짐을 챙기지 말고 현관으로 나가자."
		"landing": return "초록 비상등을 따라가자. 계단 옆에 점검 기록이 남아 있다."
		"threshold": return "출입문 앞이다. 손에 익은 감촉을 기억하자."
		_: return ""

static func inspect(id: String, state: Dictionary) -> Dictionary:
	var phase: String = state.get("phase", "home")
	var early: bool = phase == "home"
	var memories: Array = state.get("memories", [])
	match id:
		"notice":
			return _page("104동 야간 안내", "관리사무소 방재과 · 15층 이상 세대\n\n20:30 이후 빛이 들어오면 암막 커튼을 닫고 벨크로를 벽에 밀착하십시오. 배수구 물이 옆으로 흐르면 덮개 위에 무거운 냄비를 놓고 30분간 주방을 비우십시오. 손으로 누르지 마십시오.\n\n공동현관 화면에 단지 전체가 보이면 통화하지 말고 전원을 3초간 눌러 끄십시오. 호출이 멎을 때까지 기다리십시오. 욕실 벽의 진동이 분당 10회를 넘으면 즉시 비상계단을 이용하십시오.\n\n※ 생활용품의 경미한 손상은 원상복구될 수 있습니다. 세대 내 출입 작업은 없습니다.")
		"mark":
			if early:
				return _page("문틀", "연필선 세 개. 가장 위에는 8월 12일이라고 적혀 있다. 아버지는 숫자 2를 늘 거꾸로 쓰셨다.\n\n문틀을 새로 칠할 때도 이 부분만 남겼다. 이제는 내 눈보다 낮은 선이다.")
			return _page("문틀", "세 줄은 그대로다. 마지막 날짜의 2만 바르게 쓰여 있다.\n\n손가락으로 문질렀다. 연필 가루는 묻어나지 않는다. " + ("선 옆에 오늘 날짜가 하나 더 있다. 내 눈높이보다 조금 위다." if state.get("exposure", 0) > 1 else "페인트가 새로 칠해진 흔적도 없다."))
		"photo":
			if early:
				return _page("가족사진", "이사 온 날. 내 오른손 엄지에 붕대가 감겨 있다. 컵을 떨어뜨리고 조각을 치우다가 베었다.\n\n아버지는 사진을 찍기 전에 컵부터 버리라고 하셨다. 나는 사진을 찍고 나서도 버리지 않았다.")
			return _page("가족사진", "붕대는 왼손에 감겨 있다. 아버지 셔츠 주머니는 원래 있던 쪽이다. 사진 전체가 뒤집힌 것은 아니다.\n\n내 오른손 엄지를 엄지손톱으로 눌렀다. 흉터의 감촉은 아직 여기 있다.")
		"mug":
			if early:
				return _page("보리차 컵", "손잡이를 오른쪽으로 놓으면, 내 쪽 테두리 왼편이 조금 깨져 있다. 손가락이 그 자리를 피해 움직인다.\n\n손잡이는 늘 먼저 뜨거워진다. 그래서 몸통을 두 손으로 감싸 마셨다. 바닥에는 닦아도 남는 찻자국이 있다.")
			if phase in ["return", "dusk", "drain"]:
				return _page("보리차 컵", "손잡이를 오른쪽으로 돌렸다. 테두리를 손끝으로 다시 훑었다.\n\n걸리는 곳이 없다. 바닥의 찻자국은 그대로다.\n\n컵을 내려놓을 자리를 한참 보고 있었다.")
			return _page("보리차 컵", "이번에는 손끝에 걸린다. 손잡이를 오른쪽으로 두고 다시 보았다.\n\n빠진 자리의 크기도 깊이도 기억과 같다. 오른쪽이라는 것만 다르다.\n\n아까 이 부분을 얼마나 오래 만졌는지 생각났다.")
		"wash":
			if early and memories.size() >= 3:
				return _page("세면대", "수도꼭지에 오늘 아침 물방울 자국이 말라붙어 있다. 수건은 아직 조금 축축하다.\n\n손을 씻고 나면 남은 차를 마셔야겠다.", [_choice("손을 씻는다", "wash")])
			if early:
				return _page("세면대", "손을 씻기 전에 집 안을 조금만 더 돌아보자.\n\n문틀의 선, 거실 사진, 식탁 위 컵. 오래 비운 집도 아닌데 늘 그 자리에 있는 것을 보면 마음이 놓인다.")
			return _page("세면대", "수도꼭지는 잠겨 있다. 손을 씻은 뒤 접어 둔 수건도 그대로다.\n\n수건의 젖은 부분만 반대쪽이다.")
		"curtain":
			if phase == "dusk":
				return _page("베란다", "시계는 저녁 여덟 시 반을 넘겼다. 식탁 다리의 그림자가 창문 쪽으로 뻗어 있다.\n\n커튼 가장자리에는 벽에 붙이는 벨크로가 달려 있다. 공지에는 마지막 틈까지 막으라고 적혀 있었다.", [_choice("커튼을 닫고 벨크로를 붙인다", "seal"), _choice("틈으로 바깥을 본다", "look")])
			return _page("베란다", "맞은편 창문들이 하나씩 켜진다. 퇴근길에 매일 보던 불빛이다.\n\n차 한 잔 마시고 커튼을 닫기로 했다." if early or phase == "return" else "벨크로는 벽에 붙어 있다. 빛이 들어올 틈은 없다.\n\n바닥에는 붉은빛이 남아 있다. 손으로 가려도 밝기가 같았다.")
		"sink":
			if phase == "drain":
				return _page("싱크대", "물은 아래로 떨어지지 않고 배수구 옆면을 따라 돈다. 잠깐 멎었다가, 다시 같은 방향으로.\n\n안쪽에 흰 조각이 있다. 옆에는 아침에 씻어 둔 무쇠 냄비가 엎어져 있다. 공지에는 손으로 누르지 말라고 적혀 있었다.", [_choice("덮개 위에 무쇠 냄비를 놓는다", "cover"), _choice("흰 조각에 손을 뻗는다", "touch")])
			return _page("싱크대", "씻어 둔 무쇠 냄비가 엎어져 있다. 수도꼭지를 한 번 더 돌렸다. 이미 잠겨 있었다." if early or phase in ["return", "dusk"] else "냄비가 덮개를 누르고 있다. 이제 움직이지 않는다.\n\n주방에 남은 냄새는 세제 냄새가 아니다. 바닷가 바위틈에서 맡아 본 냄새다.")
		"wallpad":
			if phase == "signal":
				return _page("공동현관 호출", "흑백 화면에 104동 옥상이 보인다. 카메라가 있을 수 없는 높이다.\n\n화면 아래에는 익숙한 두 버튼이 있다. 통화. 전원. 방문객의 이름이 표시되는 칸은 비어 있다.", [_choice("전원을 누르고 셋을 센다", "off"), _choice("통화 버튼을 누른다", "answer")])
			return _page("월패드", "부재중 호출 0건. 화면 모서리에 아침에 묻힌 손자국이 남아 있다." if early or phase in ["return", "dusk", "drain"] else "꺼진 화면에 현관이 비친다. 손자국이 사라져 있다.\n\n깨끗해진 화면을 닦으려다가 손을 내렸다.")
		"tile":
			if phase == "pulse":
				return _page("욕실 벽", "벽에 댄 손바닥 전체로 진동이 온다. 수도는 쓰지 않고 있다.\n\n한 번이 지나가면 다음 번까지 오래 조용하다. 공지에 적힌 숫자를 떠올렸다. 한 분에 열 번.", [_choice("손을 대고 한 분 동안 센다", "count"), _choice("타일을 두 번 두드린다", "knock")])
			return _page("욕실 벽", "줄눈 끝에 작은 금이 있다. 입주할 때부터 있던 금이다. 수리해야 한다고 생각한 지 오래됐다." if early or phase in ["return", "dusk", "drain", "signal"] else "손을 떼었는데도 손바닥에 간격이 남아 있다.\n\n벽에 다시 대 볼 필요는 없다.")
		"mirror":
			return _page("거울", "피곤한 얼굴이다. 오른손 엄지의 작은 흉터를 내려다봤다. 이제 따갑지도 않다." if early else "손을 들어 보려다가 그만뒀다.\n\n내가 무엇을 확인하려는지, 아직 말로 생각하고 싶지 않다.")
		"sofa":
			return _page("소파", "늘 앉는 쪽이 조금 꺼져 있다. 아버지가 쓰시던 반대쪽 자리는 그대로다.\n\n퇴근하면 여기에 가방부터 내려놓았다." if early else "늘 앉는 쪽의 주름을 손으로 폈다.\n\n손을 떼자 반대쪽 방석이 천천히 올라왔다.")
		"door":
			if phase == "escape":
				return _page("현관문", "주머니에 수첩이 있다. 휴대전화도 있다.\n\n다른 것을 챙기러 들어가면 또 무엇을 확인하게 될지 모른다.", [_choice("문을 열고 나간다", "leave")])
			return _page("현관문", "신발장 오른쪽 접시에 열쇠를 놓았다. 손때로 한쪽 이가 닳아 문을 열 때마다 조금 걸린다.\n\n오늘은 더 나갈 일이 없다." if early else "문 아래로 복도 불빛이 가늘게 들어온다.\n\n접시의 열쇠는 그대로 있다. 지금은 집 안에서 들리는 소리를 먼저 확인해야 한다.")
		"archive", "report":
			if phase == "landing" and not state.get("report", false):
				return _page("점검 기록", "1994년 8월 12일 · 제1공구 항타 작업 중단\n\n지하 45m에서 파일 반발. 회색 액체 유출. 암반 판정 보류. 제거 불가. 콘크리트 3m 덧씌우기 승인.\n\n별지: 깨진 계측기 외장이 복구됨. 눈금은 반대로 새겨짐. 반복 확인 후 오차 감소. 마지막 문장에만 밑줄이 있다.\n『원래 상태와 정상 상태를 혼동하지 말 것.』", [_choice("일지의 날짜와 문장을 수첩에 옮긴다", "archive"), _choice("기록을 내려놓는다", "")])
			return _page("점검 기록", "옮겨 적은 문장을 다시 읽었다.\n\n원래 상태와 정상 상태를 혼동하지 말 것.\n\n종이는 그대로 두었다. 접힌 모서리와 묵은 손때까지 오래된 채로 남아 있다.")
		"elevator":
			if phase == "landing" and not state.get("visited_elevator", false):
				return _page("엘리베이터", "문이 열린 채 기다리고 있다. 정면의 전망 유리에는 복도 불빛이 희미하게 비친다.\n\n공지는 비상계단을 이용하라고 했다.", [_choice("문 밖에서 내부를 확인한다", "elevator"), _choice("계단으로 발을 돌린다", "")])
			return _page("엘리베이터", "문이 닫혀 있다. 표시기는 여전히 15층이다.\n\n문 앞에서 조금 물러났다.")
		"exit", "stairs":
			if phase == "landing":
				return _page("비상계단", "초록 비상등 아래로 계단이 이어진다. 방화문 손잡이는 차갑다.\n\n아래에서는 사람 목소리가 들리지 않는다.", [_choice("계단을 따라 지상으로 내려간다", "exit")])
			if phase == "threshold":
				return _page("출입문", "우리 집 신발장에 있던 접시가 문 앞에 놓여 있다. 열쇠는 두 개다. 한쪽 이가 닳은 열쇠와, 같은 모양의 새 열쇠.\n\n유리문 안내에는 이렇게 적혀 있다.\n『출입 불량 방지를 위해 원상복구된 열쇠를 사용하십시오.』\n\n닳은 쪽을 쥐면 엄지가 익숙한 홈에 들어간다.", [_choice("닳은 열쇠로 문을 연다", "worn"), _choice("새 열쇠로 문을 연다", "new")])
	return _page("잠시", "가만히 서서 집 안의 소리를 들었다.")

static func outcome(action: String, state: Dictionary) -> Dictionary:
	match action:
		"wash": return _page("손을 닦았다", "물을 잠그고 수건을 접었다. 거실 쪽에서 작은 소리가 났다. 컵을 식탁에 내려놓는 소리와 비슷했다.\n\n나는 컵을 만지지 않았다.\n\n차가 식기 전에 돌아가자.")
		"mug": return _page("식탁 앞", "손을 씻는 동안 누가 들어왔을 리 없다.\n\n컵을 내려놓았다. 그제야 거실이 너무 밝다는 생각이 들었다.")
		"seal": return _page("마지막 틈", "커튼을 당기고 벨크로를 위에서부터 눌렀다. 끝까지 붙이고 나서 손을 떼었다.\n\n잠깐은 조용했다. 주방에서 물 빠지는 소리가 시작됐다.")
		"look": return _page("창가", "틈 너머에 식탁 다리가 보였다. 우리 집 식탁의 안쪽 면에 있는 긁힌 자국까지 같았다.\n\n커튼을 끝까지 닫고 벨크로를 붙였다. 손을 오래 대고 있지는 않았다.\n\n주방에서 물 빠지는 소리가 났다.")
		"cover": return _page("냄비", "배수구 덮개를 닫고 무쇠 냄비를 올렸다. 손잡이를 놓자 냄비가 아주 조금 움직였다.\n\n주방 밖에서 삼십 분을 보냈다. 냉장고 돌아가는 소리가 다시 들렸을 때에야 시간이 갔다는 것을 알았다.\n\n한참 뒤, 현관에서 호출 벨이 울렸다.")
		"touch": return _page("흰 조각", "조각 끝이 손톱에 닿았다. 컵에서 빠졌던 모양이다. 잡으려 하자 물이 손가락 둘레에 달라붙었다.\n\n손을 뺐다. 덮개를 닫고 무쇠 냄비를 올린 뒤 주방을 벗어났다. 삼십 분 동안 손끝의 감촉이 가시지 않았다.\n\n소리가 멎고 한참 뒤, 현관에서 호출 벨이 울렸다.")
		"off": return _page("전원", "버튼을 누르고 셋을 셌다. 꺼지기 직전 화면 아래에 작은 글씨가 나타났다.\n『1504호 · 응답 방식: 관찰』\n\n집 안의 전기를 끄고 기다렸다. 벨은 열 번 울린 뒤 멎었다. 나는 통화 버튼을 누르지 않았다.\n\n자정을 넘기자 욕실 쪽에서 느린 진동이 전해졌다.")
		"answer": return _page("통화", "누가 왔는지 묻기도 전에 목소리가 들렸다.\n『네, 집에 있어요.』\n내 목소리였다. 야근한 날의 말끝까지 같았다.\n\n전원을 껐다. 집 안의 전기도 끄고, 호출이 열 번 울리다 멎을 때까지 기다렸다.\n\n자정을 넘기자 욕실 쪽에서 느린 진동이 전해졌다.")
		"count": return _page("한 분", "처음 한 분은 네 번이었다. 다음은 일곱 번. 그다음은 열 번.\n\n시계가 한 분을 다 채우기 전에 열한 번째가 왔다.\n\n손을 뗐다. 짐을 챙기지 말 것. 그 문장만 기억하면 된다.")
		"knock": return _page("두 번", "타일을 두 번 두드렸다. 같은 간격으로 두 번이 돌아왔다.\n\n기다리지 않았는데 한 번이 더 왔다. 시계를 보며 다시 세었다. 한 분에 열한 번.\n\n손을 뗐다. 현관으로 가야 한다.")
		"leave": return _page("15층", "문을 닫았다. 복도에는 아무도 없다.\n\n멀리서부터 도어록 잠기는 소리가 차례로 났다. 문이 열리는 소리는 듣지 못했다.\n\n비상등은 켜져 있다. 계단 옆 점검함에 오래된 종이가 꽂혀 있다.")
		"archive": return _page("옮겨 적은 문장", "연필을 쥐고 날짜와 마지막 문장을 옮겼다. 아버지의 숫자 2도 옆에 그렸다.\n\n어느 쪽이 맞는지 설명하는 대신, 처음 본 것을 적었다.\n\n접힌 종이 사이에 작은 메모가 끼어 있다.\n『출입문에서는 손때가 남은 열쇠를 사용할 것.』")
		"elevator": return _page("열린 문", "타지 않고 안을 들여다봤다. 전망 유리 바로 바깥에 검은 면이 붙어 있다. 긁힌 유리보다 그 표면의 주름이 더 또렷하다.\n\n거울을 등지고 귀를 막았다. 문이 닫힐 때까지 층수 표시만 보았다. 숫자는 한 번도 바뀌지 않았다.\n\n계단 쪽으로 돌아섰다.")
		"exit": return _page("지상", "열네 층을 내려왔다. 계단의 닳은 자국은 매 층 같은 곳에 있었다. 손잡이에서 손을 떼고 남은 층수를 셌다.\n\n1층. 유리문 너머는 어둡다. 바깥에 가로등 하나가 켜져 있다.\n\n문 앞에 작은 접시가 놓여 있다.")
		"worn", "new":
			var last: Dictionary = ending(state)
			return _page(last.title, last.body)
	return _page("잠시", "수첩을 접어 주머니에 넣었다.")

static func notebook(state: Dictionary) -> String:
	var lines: Array[String] = ["1504호 · 처음 본 것"]
	var memories: Array = state.get("memories", [])
	if memories.has("mark"): lines.append("문틀: 연필선 세 개. 8월 12일. 아버지의 2는 거꾸로.")
	if memories.has("photo"): lines.append("사진: 붕대는 내 오른손 엄지. 아버지 셔츠 주머니는 왼쪽.")
	if memories.has("mug"): lines.append("컵: 손잡이를 오른쪽에 두면 깨진 자리는 내 쪽 왼편. 바닥에 찻자국.")
	if memories.is_empty(): lines.append("퇴근하고 집에 들어왔다. 보리차 냄새가 난다.")
	if state.get("notice", false):
		lines.append("야간 수칙: 커튼의 틈까지 밀착. 배수구는 덮개와 냄비, 30분 대기. 월패드는 통화 없이 전원 3초. 호출이 멎을 때까지 대기. 욕실 진동이 분당 10회를 넘으면 비상계단.")
	var history: Array = state.get("history", [])
	if history.has("wash"): lines.append("손을 씻는 동안 거실에서 컵 내려놓는 소리를 들음.")
	if history.count("mug") > 1: lines.append("컵의 찻자국은 같은데, 테두리가 매끈해졌다.")
	if history.has("off"): lines.append("통화하지 않음. 화면에는 ‘응답 방식: 관찰’.")
	if state.get("voice", false): lines.append("월패드에서 내 목소리를 들음. 나는 아무 말도 하지 않았음.")
	if history.has("count") or history.has("knock"): lines.append("욕실 벽: 한 분이 끝나기 전에 열한 번째 진동. 집을 나가야 함.")
	if state.get("report", false): lines.append("1994.08.12 감리 기록: 반발하는 지층. 회색 액체. 제거 불가, 3m 덧씌움. 계측기 외장 복구, 눈금 반전. 반복 확인 후 오차 감소.\n원래 상태와 정상 상태를 혼동하지 말 것. 출입문에서는 손때가 남은 열쇠.")
	return "\n\n".join(lines)

static func ending(state: Dictionary) -> Dictionary:
	var kind: String = state.get("ending", "survivor")
	if kind == "registered":
		return {"title":"기존 세대", "body":"새 열쇠는 한 번도 걸리지 않고 돌아갔다. 문을 열자 보리차 냄새가 났다.\n\n신발장 오른쪽 접시. 거꾸로 쓴 2. 오른손의 붕대. 왼쪽이 깨진 컵. 이번에는 틀린 곳이 없었다.\n\n신발을 벗으려다 멈췄다. 내가 신고 온 신발이 안쪽에 이미 놓여 있었다.", "footnote":"1504호 원상복구 완료. 기존 거주민 이의 없음."}
	if kind == "witness":
		return {"title":"처음 본 것", "body":"닳은 열쇠가 한 번 걸렸다가 돌아갔다. 늘 그랬듯이. 문밖에서 찬 바람이 불었다.\n\n수첩을 폈다. 컵은 왼쪽. 붕대는 오른손. 아버지의 2는 거꾸로. 틀린 기억이어도 지우지 않기로 했다.\n\n마지막 장에 문장이 하나 더 있었다. 내 글씨와 아주 비슷했다.\n『이제 맞습니까.』", "footnote":"나는 답을 적지 않았다. 종이의 접힌 자국만 더 깊게 눌렀다."}
	return {"title":"정상 퇴실", "body":"닳은 열쇠로 문을 열었다. 밖에는 평범한 아파트가 서 있었다. 창 하나가 아직 붉었다. 휴대전화 사진에는 그 빛이 나오지 않았다.\n\n너무 피곤했던 것 같았다. 누구에게 설명할 말도, 옮겨 온 기록도 없었다.\n\n화면을 끄려고 손을 들었다. 엄지의 오래된 흉터가 왼손에 있었다.", "footnote":"어느 손이었는지 잠깐 생각했다. 더는 확인하지 않았다."}
