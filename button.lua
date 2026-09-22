function Button(text, func, func_param, width, height, font_size, sprite)
    return {
        width = width or 100,
        height = height or 100,
        func = func or function () print("This button has no function attached") end,
        func_param = func_param,
        text = text or "No text",
        font_size = font_size or 32,
        sprite = sprite,
        button_x = 0,
        button_y = 0,
        text_x = 0,
        text_y = 0,

        checkPressed = function (self, mouse_x, mouse_y, sounds)
            if (mouse_x >= self.button_x) and (mouse_x <= self.button_x + self.width) then
                if (mouse_y >= self.button_y) and (mouse_y <= self.button_y + self.height) then
                    if self.func_param then
                        self.func(self.func_param)
                        sounds.click:play()
                    else
                        self.func()
                        sounds.click:play()
                    end
                end
            end
        end,

        draw = function (self, button_x, button_y, text_x, text_y)
            self.button_x = button_x or self.button_x
            self.button_y = button_y or self.button_y

            if text_x then
                self.text_x = text_x + self.button_x
            else
                self.text_x = self.button_x
            end

            if text_y then
                self.text_y = text_y + self.button_y
            else
                self.text_y = self.button_y
            end

            if self.sprite then
                love.graphics.setColor(1, 1, 1) -- Reset color for correct sprite rendering
                love.graphics.draw(self.sprite, self.button_x, self.button_y, 0, self.width / self.sprite:getWidth(), self.height / self.sprite:getHeight())
            else
                -- Fallback if no sprite is provided
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.rectangle("fill", self.button_x, self.button_y, self.width, self.height)
            end

            -- Set the font with the appropriate size
            love.graphics.setFont(Fonts[self.font_size])

            -- Draw the text with the custom font
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(self.text, self.button_x, self.button_y + (self.height / 2) - (Fonts[self.font_size]:getHeight() / 2), self.width, "center")

            -- Reset the color to white for subsequent drawing
            love.graphics.setColor(1, 1, 1)
        end
    }
end

return Button