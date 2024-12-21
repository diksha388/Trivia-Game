// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TriviaGame {
    address public owner;
    uint256 public rewardPool;
    uint256 public questionCounter;

    struct Question {
        string questionText;
        string[] options;
        uint8 correctOptionIndex;
        uint256 rewardAmount;
    }

    mapping(uint256 => Question) public questions;
    mapping(address => uint256) public playerBalances;

    event QuestionAdded(uint256 questionId, string questionText, uint256 rewardAmount);
    event AnswerSubmitted(address player, uint256 questionId, bool isCorrect);
    event RewardsWithdrawn(address player, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addQuestion(
        string memory _questionText,
        string[] memory _options,
        uint8 _correctOptionIndex,
        uint256 _rewardAmount
    ) public onlyOwner {
        require(_correctOptionIndex < _options.length, "Invalid correct option index.");
        require(_rewardAmount <= rewardPool, "Insufficient reward pool.");

        questions[questionCounter] = Question({
            questionText: _questionText,
            options: _options,
            correctOptionIndex: _correctOptionIndex,
            rewardAmount: _rewardAmount
        });

        rewardPool -= _rewardAmount;

        emit QuestionAdded(questionCounter, _questionText, _rewardAmount);
        questionCounter++;
    }

    function answerQuestion(uint256 _questionId, uint8 _selectedOption) public {
        Question storage question = questions[_questionId];
        require(_selectedOption < question.options.length, "Invalid option selected.");

        bool isCorrect = (_selectedOption == question.correctOptionIndex);
        if (isCorrect) {
            playerBalances[msg.sender] += question.rewardAmount;
        }

        emit AnswerSubmitted(msg.sender, _questionId, isCorrect);
    }

    function depositRewards() public payable onlyOwner {
        rewardPool += msg.value;
    }

    function withdrawRewards() public {
        uint256 amount = playerBalances[msg.sender];
        require(amount > 0, "No rewards to withdraw.");

        playerBalances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit RewardsWithdrawn(msg.sender, amount);
    }
}