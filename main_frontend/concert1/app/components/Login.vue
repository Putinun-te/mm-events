<template>
    <div class="flex items-center justify-center h-screen">
        <form>
            <div class="bg-white w-96 p-6 rounded shadow-sm">
                <div class="flex items-center justify-center mb-4">
                    <img src="~/assets/img/apple.jpg" class="h-32"/>
                </div>
                    <div class="bg-red-500 px-3 py-2 rounded text-gray-100">
                        <p>test</p>
                    </div>
                <label class="text-grey-700">Email</label>
                <input class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4" type="email"/>
                <label class="text-grey-700">Password</label>
                <input class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4" type="password"/>
                <input class="mb-4" type="checkbox" id="remember"/>
                <label class="text-gray-300" for="remember">Remember</label>
                <button type="submit" class="bg-blue-500 w-full text-gray-100 py-2 rounded hover:bg-blue-500 transition-colors">Login</button>
            </div>
        </form>
    </div>
</template>