;; 패키지 매니저 설정
(require 'package)
(setq package-archives
      '(("melpa"  . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("gnu"    . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; use-package 설치
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Disable ring-bell
(setq ring-bell-function 'ignore)

;; Treemacs
(use-package treemacs
  :demand t

  :config
  (setq treemacs-space-between-root-nodes nil) ;; Remove extra space between projects(root node)
  (setq treemacs-read-string-input 'from-minibuffer) ;; Read input from minibuffer instead of child-frame popup

  :bind ("C-x t t" . treemacs))

;; Nerd Icons 지원 (터미널에서도 아이콘 표시)
(use-package nerd-icons)

;; Treemacs + Nerd Icons 연동
(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(package-vc-selected-packages
   '((copilot :vc-backend Git :url
			  "https://github.com/copilot-emacs/copilot.el"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Line number
(setq display-line-numbers-type t)
;; Turn on line number
(global-display-line-numbers-mode 1)

;; Default indentation (4 spaces/tabs)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Add lisp directory to load path
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; Appearance
(require 'appearance)

;; Themes
(require 'themes)

;; Dashboard
(require 'init-dashboard)

;; Markdown
(require 'markdown)

;; Languages
(require 'languages)

;; Artificial Intelligence
(require 'agent)

;; Corfu (atuo-completion pop-up)
(use-package corfu
  :custom
  (corfu-auto t)              ;; Enable auto-completion
  (corfu-auto-prefix 2)       ;; Trigger after typing 2 character (changed from 2)
  (corfu-auto-delay 0.3)      ;; Delay 0.3s before showing pop-up
  (corfu-quit-at-boundary t)  ;; Quit pop-up at completion boundary
  (corfu-quit-no-match t)     ;; Quit pop-up when no matches found
 
  ;; Visual
  ;; (corfu-margin-width 1)      ;; Add margin to the pop up
  ;; (corfu-bar-width 1)         ;; Make vertical bar thinner
    
  :init
  (global-corfu-mode)         ;; Enable globally
  (corfu-popupinfo-mode t))   ;; Show documentation in a companion popup

(use-package corfu-terminal
  :ensure t
  :init
  (unless (display-graphic-p)
    (corfu-terminal-mode +1)))

;; Eldoc-box
(use-package eldoc-box
  :ensure t
  ;; Popup eldoc box on cursor functions
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)

  :config
  ;; Popup box after 1500 ms
  (setq eldoc-idle-delay 1.5)
  
  ;; Show eldoc buffer manually
  (defun popup-eldoc-buffer ()
    (interactive)
    (let* ((buf (eldoc-doc-buffer))
           (doc-window (and buf (get-buffer-window buf))))
      (if doc-window
          (delete-window doc-window)
        (when buf
          (display-buffer buf
                          '(display-buffer-at-bottom
                            (window-height . fit-window-to-buffer)))))))

  :bind
  ("C-c h" . popup-eldoc-buffer))

;; Vertico
(use-package vertico
  :ensure t

  :init
  (vertico-mode))

;; Marginalia (add descriptions to completion candidates)
(use-package marginalia
  :ensure t

  :init
  (marginalia-mode))

;; Orderless (flexible completion matching)
(use-package orderless
  :ensure t

  :custom
  (completion-styles '(orderless basic)))

;; Consultant (enhanced search and navigation)
(use-package consult
  :ensure t
  :bind

  (("C-s" . consult-line)       ;; Replace default search
   ("C-c f" . consult-find)     ;; Find files in project
   ("C-c r" . consult-ripgrep)  ;; Project-wide grep
   ("C-x b" . consult-buffer)   ;; Enhanbed buffer switch
   ("C-c i" . consult-imenu)))  ;; Jump to function/class

;; Magit
(use-package magit
  :ensure t

  :bind
  ("C-c g" . magit-status))

;; diff-hl (git change indicators in the gutter)
(use-package diff-hl
  :ensure t

  :init
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode)

  :hook
  (magit-post-refresh . diff-hl-magit-post-refresh))

;; vterm (full terminal emulator)
(use-package vterm
  :ensure t

  :bind
  ("C-c t" . vterm))

;; Which-key (show available keybindings)
(use-package which-key
  :ensure t

  :init
  (which-key-mode))

;; Embark (contextual actions)
(use-package embark
  :ensure t
  :bind
  ("C-c e" . embark-act))

;; Consult integration for Embark
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; Copilot
(unless (package-installed-p 'copilot)
  (package-vc-install "https://github.com/copilot-emacs/copilot.el"))

(use-package copilot
  :hook (prog-mode . copilot-mode)
  :custom (copilot-idle-delay 2.0)
  :bind (:map copilot-mode-map
              ("C-c c" . copilot-complete)
         :map copilot-completion-map
              ("M-RET" . copilot-accept-completion)
              ("M-]" . copilot-next-completion)
              ("M-[" . copilot-previous-completion)))

;; Auto close warning buffers after 5 seconds
(defun auto-close-warning-buffer ()
  (when-let ((buf (get-buffer "*Warnings*")))
	(when-let ((win (get-buffer-window buf)))
	  (run-with-timer 5 nil (lambda (w)
							  (when (window-live-p w)
								(delete-window w)))
					  win))))
(add-hook 'after-init-hook
		  (lambda ()
		  (advice-add 'display-warning :after
					  (lambda (&rest _) (auto-close-warning-buffer)))))
