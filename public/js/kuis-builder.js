document.addEventListener("DOMContentLoaded", () => {
    const questionsContainer = document.getElementById("questionsContainer");
    const questionTemplate = document.getElementById("questionTemplate");
    const answerTemplate = document.getElementById("answerTemplate");
    const questionCount = document.getElementById("questionCount");
    const form = document.getElementById("quizForm");
    const statusInput = document.getElementById("statusInput");
    const statusBadge = document.getElementById("statusBadge");

    let questionIndex = 0;

    function createQuestion() {
        const html = questionTemplate.innerHTML.replaceAll("__INDEX__", questionIndex);
        questionsContainer.insertAdjacentHTML("beforeend", html);

        const card = questionsContainer.lastElementChild;
        const answers = card.querySelector(".answers-container");

        // Default 4 choices seperti desain Figma.
        addAnswer(card, questionIndex);
        addAnswer(card, questionIndex);
        addAnswer(card, questionIndex);
        addAnswer(card, questionIndex);

        questionIndex++;
        refreshQuestionNumbers();
        return card;
    }

    function addAnswer(questionCard, indexOverride = null) {
        const qIndex = indexOverride ?? questionCard.dataset.questionIndex;
        const answersContainer = questionCard.querySelector(".answers-container");
        const answerIndex = answersContainer.children.length;

        const html = answerTemplate.innerHTML
            .replaceAll("__INDEX__", qIndex)
            .replaceAll("__ANSWER_INDEX__", answerIndex);

        answersContainer.insertAdjacentHTML("beforeend", html);
        refreshAnswerLabels(questionCard);
    }

    function refreshQuestionNumbers() {
        const cards = [...questionsContainer.querySelectorAll(".question-card")];
        cards.forEach((card, index) => {
            card.dataset.questionIndex = index;
            card.querySelector(".question-number").textContent = index + 1;

            card.querySelectorAll("input, textarea").forEach(el => {
                if (el.name.includes("questions[")) {
                    el.name = el.name.replace(/questions\[\d+\]/, `questions[${index}]`);
                }
            });

            refreshAnswerLabels(card);
        });

        questionCount.textContent = cards.length;
    }

    function refreshAnswerLabels(questionCard) {
        const answers = [...questionCard.querySelectorAll(".answer-card")];

        answers.forEach((answer, index) => {
            answer.dataset.answerIndex = index;
            answer.querySelector(".answer-label").textContent =
                String.fromCharCode(65 + index);

            answer.querySelectorAll("input, textarea").forEach(el => {
                if (el.name.includes("[options]")) {
                    el.name = el.name
                        .replace(/questions\[\d+\]/, `questions[${questionCard.dataset.questionIndex}]`)
                        .replace(/\[options\]\[\d+\]/, `[options][${index}]`);
                }
                if (el.classList.contains("correct-radio")) {
                    el.value = index;
                    el.name = `questions[${questionCard.dataset.questionIndex}][correct_answer]`;
                }
            });
        });

        const checked = questionCard.querySelector(".correct-radio:checked");
        answers.forEach(answer => {
            answer.classList.toggle("correct", answer.contains(checked));
        });
    }

    function deleteQuestion(card) {
        const cards = questionsContainer.querySelectorAll(".question-card");
        if (cards.length === 1) {
            alert("Minimal harus ada 1 soal.");
            return;
        }
        card.remove();
        refreshQuestionNumbers();
    }

    function duplicateQuestion(card) {
        const clone = card.cloneNode(true);
        questionsContainer.appendChild(clone);

        // Ubah semua field ke index baru.
        const newIndex = questionsContainer.querySelectorAll(".question-card").length - 1;
        clone.dataset.questionIndex = newIndex;
        clone.querySelectorAll("input, textarea").forEach(el => {
            el.name = el.name.replace(/questions\[\d+\]/, `questions[${newIndex}]`);
        });
        clone.querySelectorAll(".correct-radio").forEach((radio, index) => {
            radio.name = `questions[${newIndex}][correct_answer]`;
            radio.value = index;
        });

        refreshQuestionNumbers();
    }

    function deleteAnswer(answer, card) {
        const answers = card.querySelectorAll(".answer-card");
        if (answers.length <= 2) {
            alert("Minimal harus ada 2 pilihan jawaban.");
            return;
        }
        answer.remove();
        refreshAnswerLabels(card);
    }

    document.getElementById("addQuestionTop").addEventListener("click", createQuestion);
    document.getElementById("addQuestionBottom").addEventListener("click", createQuestion);

    questionsContainer.addEventListener("click", e => {
        const card = e.target.closest(".question-card");
        if (!card) return;

        if (e.target.closest(".add-answer")) {
            addAnswer(card);
        }

        if (e.target.closest(".delete-question")) {
            deleteQuestion(card);
        }

        if (e.target.closest(".duplicate-question")) {
            duplicateQuestion(card);
        }

        if (e.target.closest(".delete-answer")) {
            deleteAnswer(e.target.closest(".answer-card"), card);
        }
    });

    questionsContainer.addEventListener("change", e => {
        if (e.target.classList.contains("correct-radio")) {
            const card = e.target.closest(".question-card");
            refreshAnswerLabels(card);
        }
    });

    function setStatus(status) {
        statusInput.value = status;
        statusBadge.textContent = status === "published" ? "PUBLISHED" : "DRAFT";
    }

    document.querySelectorAll("[data-submit-status]").forEach(button => {
        button.addEventListener("click", () => {
            if (!form.reportValidity()) return;

            const cards = [...questionsContainer.querySelectorAll(".question-card")];

            if (!cards.length) {
                alert("Tambahkan minimal 1 soal.");
                return;
            }

            for (const card of cards) {
                const answers = card.querySelectorAll(".answer-card");
                const correct = card.querySelector(".correct-radio:checked");

                if (answers.length < 2) {
                    alert(`Soal ${card.querySelector(".question-number").textContent} minimal memiliki 2 pilihan.`);
                    return;
                }

                if (!correct) {
                    alert(`Pilih jawaban benar untuk Soal ${card.querySelector(".question-number").textContent}.`);
                    return;
                }
            }

            setStatus(button.dataset.submitStatus);
            form.submit();
        });
    });

    // Preview sederhana.
    const previewModal = document.getElementById("previewModal");
    const previewBody = document.getElementById("previewBody");

    document.getElementById("previewBtn").addEventListener("click", () => {
        const title = document.getElementById("judul_kuis").value || "Judul Kuis";
        const description = document.getElementById("deskripsi").value || "";

        document.getElementById("previewTitle").textContent = title;
        document.getElementById("previewDescription").textContent = description;

        previewBody.innerHTML = "";

        document.querySelectorAll(".question-card").forEach((card, qIndex) => {
            const question = card.querySelector(".question-input").value || "(Pertanyaan belum diisi)";
            const wrapper = document.createElement("div");
            wrapper.className = "preview-question";

            const heading = document.createElement("strong");
            heading.textContent = `Soal ${qIndex + 1}`;
            wrapper.appendChild(heading);

            const text = document.createElement("p");
            text.textContent = question;
            wrapper.appendChild(text);

            card.querySelectorAll(".answer-card").forEach((answer, aIndex) => {
                const option = document.createElement("div");
                option.className = "preview-option";
                option.textContent = `${String.fromCharCode(65 + aIndex)}. ${answer.querySelector(".answer-input").value}`;
                wrapper.appendChild(option);
            });

            previewBody.appendChild(wrapper);
        });

        previewModal.hidden = false;
    });

    document.getElementById("closePreview").addEventListener("click", () => {
        previewModal.hidden = true;
    });

    previewModal.addEventListener("click", e => {
        if (e.target === previewModal) previewModal.hidden = true;
    });

    // Mulai dengan 2 soal seperti screenshot Figma.
    createQuestion();
    createQuestion();
});
