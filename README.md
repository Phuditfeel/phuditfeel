สมาร์ทคอนแทรกต์นี้ประกอบด้วยหลายส่วน:

CommitReveal.sol: ใช้สำหรับการแฮช commit เพื่อปกปิดตัวเลือกของผู้เล่นจนกว่าจะเปิดเผย
TimeUnit.sol: ให้ฟังก์ชันเกี่ยวกับการจัดการเวลา เช่น การดึงเวลาปัจจุบัน
RPSGame.sol: เป็นคอนแทรกต์หลักที่รวม CommitReveal และ TimeUnit และจัดการกับลอจิกของเกม
เกมนี้ใช้กฎของ Rock-Paper-Scissors ซึ่งผู้เล่นต้องทำการ commit ตัวเลือกของตนเองอย่างปลอดภัย จากนั้นเปิดเผยตัวเลือกและตัดสินผู้ชนะตามกฎของเกม ผู้เล่นจะต้องส่ง 1 Ether เพื่อเข้าร่วม และผู้ชนะจะได้รับรางวัลทั้งหมด

ฟีเจอร์หลัก
1. ป้องกันการ lock เงินไว้ในคอนแทรกต์
เพื่อป้องกันไม่ให้เงินถูก lock ไว้ในคอนแทรกต์โดยไม่สามารถถอนออกได้ สมาร์ทคอนแทรกต์มีฟังก์ชัน forceWithdraw() ที่อนุญาตให้ผู้เล่นถอนเงินได้หากเกมไม่สมบูรณ์ (เช่น ผู้เล่นไม่ครบ 2 คน หรือยังไม่มีการเปิดเผยตัวเลือก) ซึ่งเงื่อนไขสำหรับการถอนมีดังนี้:

กรณี 1: หากมีผู้เล่นเพียงคนเดียว พวกเขาสามารถถอนเงินรางวัลทั้งหมดได้
กรณี 2: หากมีผู้เล่น 2 คน และเวลาการเปิดเผยหมดแล้ว (ควบคุมโดย revealDeadline) ผู้เล่นที่เปิดเผยตัวเลือกแล้วสามารถถอนเงินรางวัลได้
solidity
Copy
Edit
function forceWithdraw() public {
    require(numPlayer == 1 || (numPlayer == 2 && block.timestamp > revealDeadline), "Cannot withdraw yet");

    if (numPlayer == 1) {
        payable(players[0]).transfer(reward);
    } else {
        if (hasRevealed[players[0]]) {
            payable(players[0]).transfer(reward);
        } else if (hasRevealed[players[1]]) {
            payable(players[1]).transfer(reward);
        }
    }
    _resetGame();
}
คำอธิบาย:หากมีผู้เล่น 1 คน หรือเวลาการเปิดเผยหมดแล้ว (เกิน revealDeadline) คอนแทรกต์อนุญาตให้ถอนเงินได้
ฟังก์ชันนี้ช่วยหลีกเลี่ยงการที่เงินถูกล็อคไว้นานเกินไปหากเกมไม่สมบูรณ์
2. การซ่อนตัวเลือกและ commit เพื่อให้มั่นใจว่าไม่สามารถเปลี่ยนแปลงตัวเลือกหลังจากที่ผู้เล่น commit แล้ว คอนแทรกต์จะใช้วิธีการแฮช (hashing) โดยผู้เล่นจะทำการแฮชตัวเลือกของตนเองร่วมกับ string ลับ (secret) ก่อนที่จะแชร์ commit นี้ไปยังคอนแทรกต์ การแฮชนี้จะเก็บข้อมูลไว้ในคอนแทรกต์จนกว่าจะถึงเวลาที่ผู้เล่นเปิดเผยตัวเลือก

ฟังก์ชัน addPlayer จะเก็บ commit hash ดังนี้:

solidity
Copy
Edit
function addPlayer(bytes32 commitHash) public payable onlyAllowedPlayers {
    require(numPlayer < 2, "Game is full");
    require(msg.value == 1 ether, "Must send exactly 1 ether");
    if (numPlayer > 0) require(msg.sender != players[0], "Same player twice");
    
    reward += msg.value;
    players.push(msg.sender);
    playerCommit[msg.sender] = commitHash;
    numPlayer++;

    if (numPlayer == 2) {
        revealDeadline = block.timestamp + 5 minutes;
    }
}
คำอธิบาย:commit hash จะถูกสร้างจาก keccak256 ของตัวเลือกและ secret string ก่อนที่จะเข้าร่วมเกม ซึ่งทำให้ไม่สามารถรู้ตัวเลือกของผู้เล่นได้จนกว่าจะเปิดเผย
ผู้เล่นไม่สามารถเปลี่ยนแปลงตัวเลือกหลังจากที่ commit ไปแล้ว ทำให้การเล่นเกมยุติธรรม
3.การจัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนหากผู้เล่นไม่ครบ 2 คน หรือไม่สามารถเปิดเผยตัวเลือกได้ภายในเวลาที่กำหนด (ผ่าน revealDeadline) คอนแทรกต์จะอนุญาตให้ผู้เล่นทำการถอนเงินผ่านฟังก์ชัน forceWithdraw
solidity
Copy
Edit
function forceWithdraw() public {
    require(numPlayer == 1 || (numPlayer == 2 && block.timestamp > revealDeadline), "Cannot withdraw yet");

    if (numPlayer == 1) {
        payable(players[0]).transfer(reward);
    } else {
        if (hasRevealed[players[0]]) {
            payable(players[0]).transfer(reward);
        } else if (hasRevealed[players[1]]) {
            payable(players[1]).transfer(reward);
        }
    }
    _resetGame();
}
คำอธิบาย:หากมีผู้เล่นเพียงคนเดียว ก็สามารถถอนเงินได้ทันที
หากมีผู้เล่น 2 คน และหมดเวลาเปิดเผย แต่ยังไม่มีการเปิดเผยตัวเลือก ฟังก์ชันจะถอนเงินให้ผู้เล่นที่เปิดเผยตัวเลือกแล้ว
ฟังก์ชันนี้ช่วยให้ผู้เล่นไม่ต้องรอเกินความจำเป็นหากเกมไม่สมบูรณ์
4.การเปิดเผยตัวเลือกและการตัดสินผู้ชนะเมื่อผู้เล่นทั้งสองได้ commit ตัวเลือกแล้ว พวกเขาสามารถเปิดเผยตัวเลือกของตนผ่านฟังก์ชัน revealChoice() ซึ่งจะตรวจสอบว่า choice ที่เปิดเผยตรงกับ commit หรือไม่ และถ้าทั้งสองฝ่ายเปิดเผยแล้ว เกมจะตรวจสอบผลและตัดสินผู้ชนะ
solidity
Copy
Edit
function revealChoice(uint choice, bytes32 secret) public {
    require(numPlayer == 2, "Game not ready");
    require(!hasRevealed[msg.sender], "Already revealed");
    require(getHash(keccak256(abi.encodePacked(choice, secret))) == playerCommit[msg.sender], "Invalid reveal");

    playerChoice[msg.sender] = choice;
    hasRevealed[msg.sender] = true;

    if (hasRevealed[players[0]] && hasRevealed[players[1]]) {
        _checkWinnerAndPay();
    }
}
คำอธิบาย:ฟังก์ชัน revealChoice() ตรวจสอบว่า choice และ secret ที่ผู้เล่นเปิดเผยตรงกับ commit hash หรือไม่
เมื่อผู้เล่นทั้งสองเปิดเผยตัวเลือกแล้ว เกมจะดำเนินการตัดสินผลและจ่ายรางวัลตามผลลัพธ์ของเกม
การตัดสินผู้ชนะ:

solidity
Copy
Edit
function _checkWinnerAndPay() private {
    uint p0 = playerChoice[players[0]];
    uint p1 = playerChoice[players[1]];
    address payable player0 = payable(players[0]);
    address payable player1 = payable(players[1]);

    if ((p0 + 1) % 3 == p1) {
        player1.transfer(reward);
    } else if ((p1 + 1) % 3 == p0) {
        player0.transfer(reward);
    } else {
        player0.transfer(reward / 2);
        player1.transfer(reward / 2);
    }

    _resetGame();
}
คำอธิบาย:การคำนวณ (p0 + 1) % 3 ใช้เพื่อเปรียบเทียบผลลัพธ์ระหว่าง Rock, Paper, และ Scissors
หากผู้เล่นคนแรกชนะจะได้รับรางวัลทั้งหมด หรือหากเสมอกันจะมีการแบ่งรางวัลครึ่งหนึ่งให้ทั้งสองคน
หลังจากตัดสินผลเกมแล้ว คอนแทรกต์จะทำการรีเซ็ตเกมเพื่อให้ผู้เล่นใหม่เข้าร่วมได้
วิธีการใช้งานสมาร์ทคอนแทรกต์
ดีพลอยคอนแทรกต์ CommitReveal.sol, TimeUnit.sol, และ RPSGame.sol ไปยัง Ethereum network
ผู้เล่นสามารถเรียกใช้ฟังก์ชัน addPlayer() โดยส่ง commit hash เพื่อเข้าร่วมเกม
เมื่อผู้เล่นทั้งสอง commit ตัวเลือกแล้ว พวกเขาต้องเรียกใช้ฟังก์ชัน revealChoice() เพื่อเปิดเผยตัวเลือก
คอนแทรกต์จะทำการตัดสินผู้ชนะและจ่ายรางวัล หรือผู้เล่นสามารถถอนเงินโดยใช้ฟังก์ชัน forceWithdraw() หากเกมไม่สมบูรณ์
