package Forum::I18N::ru;
use base 'Forum::I18N';

use Encode 'decode';

our %Lexicon = (
    _AUTO => 1,
    'Repo'          => 'Репозиторий',
    'Repos'         => 'Репозитории',
    'New repo'      => 'Создать новый',
    'Add key'       => 'Добавить ключ',
    'name'          => 'имя',
    'members'       => 'пользователи',
    'description'   => 'описание',
    'password'      => 'пароль',
    'repeat'        => 'повторить',
    'registered'    => 'зарегистрирован',
    'Register'      => 'Регистрация',
    'ban reason'    => 'причина блокировки',
    'ban time'      => 'время блокировки',
    'now'           => 'сейчас',
    'Add'           => 'Добавить',
    'status'        => 'статус',
    'active'        => 'активный',
    'inactive'      => 'деактивирован',
    'week'          => 'неделя',
    'day'           => 'день',
    'hour'          => 'час',
    'edit'          => 'изменить',
    'delete'        => 'удалить',
    'description'   => 'описание',
   
    'ban options'   => 'блокировка',
    
    'Profile'       => 'Профиль',
    'Login'         => 'Войти',
    'Login via mail'=> 'Войти с почты',
    'Logout'        => 'Выйти',
    
    'Add server'    => 'Добавить сервер',
    
    'index'         => 'Главная',
    
    'mins1'         => 'минуту',
    'mins2'         => 'минуты',
    'mins5'         => 'минут',
    
    'hours1'        => 'час',
    'hours2'        => 'часа',
    'hours5'        => 'часов',
    
    'ago'           => 'назад',
    'createAt'      => 'время создания',
    'modifyAt'      => 'время изменения',
    'accessAt'      => 'последнее посещение',
    
    'a few seconds ago' => 'несколько секунд назад',
    'Your public key'   => 'Ваш публичный ключ',
    'Create new repo'   => 'Создать новый репозиторий',
    'Repository list'   => 'Список репозиториев',
    'change password'   => 'сменить пароль',
    'How to create new repository' => 'Как создать новый репозиторий',
    'Add server public key'        => 'Добавить публичный ключ сервера',
    'This page does not exist or you can\'t read it.' => 'Эта страница не существует, или у Вас не хватает прав.',
    
    'Forum'         => 'Форум',
    'Admin panel'   => 'Администрировать',
    'User list'     => 'Список пользователей',
    'Thread list'   => 'Список тредов',
    'Group list'    => 'Список групп',
    'Thread type list'  => 'Список типов тредов',

    'response'      => 'ответить',
    'create topic'  => 'создать тему',
    'hide'          => 'скрыть',
    'Edit post'     => 'Редактировать',
    'Go to thread'  => 'Перейти к треду',
    'mail'          => 'E-mail',
    'banTime'       => 'время блокирования',
    'never'         => 'никогда',
    'add'           => 'добавить',
    'remove'        => 'убрать',
    'Delete user'   => 'Удалить пользователя',
    'Add root thread'   => 'Добавить корневой тред',
    'Create new topic'  => 'Создать новую тему',
    'Add new'       => 'Добавить ещё',
    'prioritet'     => 'приоритет',
    'rights'        => 'права',
    'Send'          => 'Отправить',
);

$Lexicon{$_} = decode('utf8', $Lexicon{$_}) for keys %Lexicon;

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

